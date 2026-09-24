import AppKit
import SwiftUI

@main
struct MeterApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let delegate = MeterAppDelegate()
        application.delegate = delegate
        application.run()
    }
}

@MainActor
final class MeterAppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let reader = NetworkInterfaceReader()
    private let state = MeterState()
    private let popover = NSPopover()
    private var detailsWindow: NSPanel?
    private var calculator = TrafficRateCalculator()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.isVisible = true
        updateTitle(with: .zero)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MeterPopoverView(state: state))
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sample() }
        }
        timer?.tolerance = 0.1

        if !UserDefaults.standard.bool(forKey: "hasShownFirstLaunchWindow") {
            DispatchQueue.main.async { [weak self] in
                self?.showDetailsWindow()
                UserDefaults.standard.set(true, forKey: "hasShownFirstLaunchWindow")
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDetailsWindow()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func sample() {
        guard let snapshot = reader.snapshot() else {
            calculator.reset()
            state.interfaceName = nil
            state.rate = .zero
            updateTitle(with: .zero)
            return
        }
        state.interfaceName = snapshot.interfaceName
        state.rate = calculator.calculate(snapshot) ?? .zero
        updateTitle(with: state.rate)
    }

    private func updateTitle(with rate: TrafficRate) {
        let title = "↓\(RateFormatter.menuBarString(bytesPerSecond: rate.downloadBytesPerSecond)) ↑\(RateFormatter.menuBarString(bytesPerSecond: rate.uploadBytesPerSecond))"
        if statusItem.button?.title != title {
            statusItem.button?.title = title
        }
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        let description = "Download \(RateFormatter.string(bytesPerSecond: rate.downloadBytesPerSecond)), upload \(RateFormatter.string(bytesPerSecond: rate.uploadBytesPerSecond))"
        statusItem.button?.toolTip = description
        statusItem.button?.setAccessibilityLabel(description)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        detailsWindow?.orderOut(nil)
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NSApp.activate()
    }

    private func showDetailsWindow() {
        if detailsWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            panel.title = "Meter"
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isReleasedWhenClosed = false
            panel.contentViewController = NSHostingController(rootView: MeterPopoverView(state: state))
            panel.center()
            detailsWindow = panel
        }
        detailsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}
