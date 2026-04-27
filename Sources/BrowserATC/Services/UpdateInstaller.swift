import AppKit
import CryptoKit
import Foundation

enum UpdateInstallError: LocalizedError {
    case noAsset
    case notWritable(String)
    case extractFailed(String)
    case bundleInvalid
    case versionMismatch(expected: String, actual: String)
    case checksumMismatch
    case helperFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAsset:
            "This release does not include a downloadable build."
        case .notWritable(let path):
            "Cannot write to \(path). Move BrowserATC.app to a writable location and try again."
        case .extractFailed(let msg):
            "Failed to extract the update: \(msg)"
        case .bundleInvalid:
            "The downloaded build does not look like a valid BrowserATC.app."
        case .versionMismatch(let expected, let actual):
            "Downloaded build has version \(actual) but \(expected) was expected."
        case .checksumMismatch:
            "Downloaded build failed checksum verification."
        case .helperFailed(let msg):
            "Could not start the update helper: \(msg)"
        }
    }
}

@MainActor
@Observable
final class UpdateInstaller {
    static let shared = UpdateInstaller()

    enum Phase: Equatable {
        case idle
        case downloading(progress: Double)
        case extracting
        case readyToInstall
        case installing
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private var stagedAppURL: URL?
    private var workDir: URL?
    private var currentTask: Task<Void, Never>?
    private var activeDownloader: UpdateDownloader?

    var isBusy: Bool {
        switch phase {
        case .downloading, .extracting, .installing: true
        default: false
        }
    }

    func start(release: LatestRelease) {
        guard !isBusy else { return }
        if case .readyToInstall = phase { return }

        guard let downloadURL = release.downloadURL else {
            phase = .failed(UpdateInstallError.noAsset.localizedDescription)
            return
        }

        cleanup()
        phase = .downloading(progress: 0)

        currentTask = Task { [weak self] in
            await self?.run(release: release, downloadURL: downloadURL)
        }
    }

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        activeDownloader?.cancel()
        activeDownloader = nil
        cleanup()
        phase = .idle
    }

    func installAndRestart() {
        guard case .readyToInstall = phase, let stagedAppURL else { return }
        phase = .installing
        do {
            try performSwap(stagedAppURL: stagedAppURL)
        } catch {
            phase = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    private func run(release: LatestRelease, downloadURL: URL) async {
        do {
            let work = try makeWorkDir()
            workDir = work

            let zipURL = work.appendingPathComponent(UpdateChecker.appBundleAssetName)
            let downloader = UpdateDownloader { [weak self] progress in
                Task { @MainActor in
                    guard let self else { return }
                    if case .downloading = self.phase {
                        self.phase = .downloading(progress: progress)
                    }
                }
            }
            activeDownloader = downloader
            defer { activeDownloader = nil }
            try await downloader.download(from: downloadURL, to: zipURL)
            try Task.checkCancellation()

            if let expected = release.downloadSHA256 {
                let actual = try sha256Hex(of: zipURL)
                guard actual.lowercased() == expected.lowercased() else {
                    throw UpdateInstallError.checksumMismatch
                }
            }

            phase = .extracting
            let extractedAppURL = try extract(zipURL: zipURL, into: work)
            try verifyBundle(at: extractedAppURL, expectedVersion: release.version)

            // Check writability of the install location early so the user gets a
            // clear error before they hit "Restart Now".
            let parentDir = URL(fileURLWithPath: Bundle.main.bundlePath).deletingLastPathComponent()
            guard FileManager.default.isWritableFile(atPath: parentDir.path) else {
                throw UpdateInstallError.notWritable(parentDir.path)
            }

            stagedAppURL = extractedAppURL
            phase = .readyToInstall
        } catch is CancellationError {
            cleanup()
            phase = .idle
        } catch {
            cleanup()
            phase = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    private func makeWorkDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserATC-Update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func extract(zipURL: URL, into dir: URL) throws -> URL {
        let extractDir = dir.appendingPathComponent("extracted")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        proc.arguments = ["-x", "-k", zipURL.path, extractDir.path]
        let stderrPipe = Pipe()
        proc.standardError = stderrPipe
        proc.standardOutput = Pipe()
        try proc.run()
        proc.waitUntilExit()

        guard proc.terminationStatus == 0 else {
            let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let msg = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? "ditto failed"
            throw UpdateInstallError.extractFailed(msg.isEmpty ? "ditto exit \(proc.terminationStatus)" : msg)
        }

        let appURL = extractDir.appendingPathComponent("BrowserATC.app")
        guard FileManager.default.fileExists(atPath: appURL.path) else {
            throw UpdateInstallError.extractFailed("BrowserATC.app missing inside archive")
        }
        return appURL
    }

    private func verifyBundle(at url: URL, expectedVersion: String) throws {
        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")
        guard let dict = NSDictionary(contentsOf: infoPlistURL) as? [String: Any],
              let actual = dict["CFBundleShortVersionString"] as? String else {
            throw UpdateInstallError.bundleInvalid
        }
        guard actual == expectedVersion else {
            throw UpdateInstallError.versionMismatch(expected: expectedVersion, actual: actual)
        }

        // Strip quarantine so Gatekeeper doesn't prompt on first launch after replacement.
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        proc.arguments = ["-dr", "com.apple.quarantine", url.path]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
    }

    private func performSwap(stagedAppURL: URL) throws {
        let currentAppURL = URL(fileURLWithPath: Bundle.main.bundlePath)
        let parentDir = currentAppURL.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: parentDir.path) else {
            throw UpdateInstallError.notWritable(parentDir.path)
        }

        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("browser-atc-update-\(UUID().uuidString).sh")
        try Self.helperScript.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755], ofItemAtPath: scriptURL.path
        )

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/bash")
        proc.arguments = [
            scriptURL.path,
            String(ProcessInfo.processInfo.processIdentifier),
            stagedAppURL.path,
            currentAppURL.path,
        ]
        proc.standardInput = nil
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        do {
            try proc.run()
        } catch {
            throw UpdateInstallError.helperFailed(error.localizedDescription)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            NSApp.terminate(nil)
        }
    }

    private func cleanup() {
        if let dir = workDir {
            try? FileManager.default.removeItem(at: dir)
            workDir = nil
        }
        stagedAppURL = nil
    }

    private func sha256Hex(of url: URL) throws -> String {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static let helperScript = """
    #!/bin/bash
    set -e

    PARENT_PID="$1"
    STAGED_APP="$2"
    TARGET_APP="$3"

    # Wait for the running app to exit (max ~30s).
    for _ in $(seq 1 150); do
        if ! kill -0 "$PARENT_PID" 2>/dev/null; then
            break
        fi
        sleep 0.2
    done

    BACKUP="${TARGET_APP}.update-backup-$$"

    if [ -d "$TARGET_APP" ]; then
        if ! mv "$TARGET_APP" "$BACKUP" 2>/dev/null; then
            exit 1
        fi
    fi

    if mv "$STAGED_APP" "$TARGET_APP" 2>/dev/null; then
        rm -rf "$BACKUP"
    else
        rm -rf "$TARGET_APP"
        if [ -d "$BACKUP" ]; then
            mv "$BACKUP" "$TARGET_APP" 2>/dev/null || true
        fi
        exit 1
    fi

    open "$TARGET_APP"

    STAGING_DIR="$(dirname "$(dirname "$STAGED_APP")")"
    case "$STAGING_DIR" in
        /tmp/*|/private/var/folders/*|/var/folders/*) rm -rf "$STAGING_DIR" ;;
    esac

    rm -- "$0" 2>/dev/null || true
    """
}

private final class UpdateDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Error>?
    private var destination: URL?
    private var session: URLSession?
    private var task: URLSessionDownloadTask?
    private var cancelled = false
    private let progressHandler: @Sendable (Double) -> Void

    init(progressHandler: @escaping @Sendable (Double) -> Void) {
        self.progressHandler = progressHandler
    }

    func download(from url: URL, to destination: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            startTask(url: url, destination: destination, continuation: continuation)
        }
        finishSession()
    }

    private func startTask(url: URL,
                           destination: URL,
                           continuation: CheckedContinuation<Void, Error>) {
        lock.lock()
        if cancelled {
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return
        }
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        self.continuation = continuation
        self.destination = destination
        self.session = session
        self.task = task
        lock.unlock()
        task.resume()
    }

    private func finishSession() {
        lock.lock()
        let session = self.session
        self.session = nil
        self.task = nil
        lock.unlock()
        session?.finishTasksAndInvalidate()
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let task = self.task
        let session = self.session
        self.task = nil
        self.session = nil
        lock.unlock()
        task?.cancel()
        session?.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        lock.lock()
        let dest = destination
        lock.unlock()
        guard let dest else { return }

        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: location, to: dest)
            resume(.success(()))
        } catch {
            resume(.failure(error))
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler(min(max(progress, 0), 1))
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error {
            resume(.failure(error))
        }
    }

    private func resume(_ result: Result<Void, Error>) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        switch result {
        case .success: cont?.resume(returning: ())
        case .failure(let err): cont?.resume(throwing: err)
        }
    }
}
