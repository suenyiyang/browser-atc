import Foundation

enum ChromeLauncher {
    private static let chromePath =
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

    static func open(url: URL, profileDirectory: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: chromePath)
        process.arguments = [
            "--profile-directory=\(profileDirectory)",
            url.absoluteString
        ]
        // Detach Chrome's stdout/stderr so it doesn't pollute our process
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try? process.run()
    }
}
