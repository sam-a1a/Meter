import AppKit
import SwiftUI

@main
struct MeterApp: App {
    @NSApplicationDelegateAdaptor(MeterAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class MeterAppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let reader = NetworkInterfaceReader()
    private let state = MeterState()
    private let popover = NSPopover()
    private var calculator = TrafficRateCalculator()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        statusItem.button?.title = "↓ \(RateFormatter.string(bytesPerSecond: rate.downloadBytesPerSecond))  ↑ \(RateFormatter.string(bytesPerSecond: rate.uploadBytesPerSecond))"
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        statusItem.button?.toolTip = "Live traffic on the active network interface"
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate()
        }
    }
}
