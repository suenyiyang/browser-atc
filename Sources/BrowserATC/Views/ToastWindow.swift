import AppKit
import SwiftUI

@MainActor
enum ToastWindow {
    private static var panel: NSPanel?
    private static var dismissTask: Task<Void, Never>?

    static func show(message: String) {
        dismissTask?.cancel()
        panel?.close()

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]

        let hostingView = NSHostingView(rootView:
            HStack(spacing: 8) {
                Image(systemName: "airplane")
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.system(.body, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .fixedSize()
        )
        let size = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: size)
        panel.setContentSize(size)
        panel.contentView = hostingView

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.maxY - 60
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }

        self.panel = panel

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            panel.animator().alphaValue = 0
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            panel.close()
            self.panel = nil
        }
    }
}
