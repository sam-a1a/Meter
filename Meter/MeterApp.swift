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
    private var calculator = TrafficRateCalculator()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateTitle(with: .zero)
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Meter", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Meter", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu

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
            updateTitle(with: .zero)
            return
        }
        updateTitle(with: calculator.calculate(snapshot) ?? .zero)
    }

    private func updateTitle(with rate: TrafficRate) {
        statusItem.button?.title = "↓ \(RateFormatter.string(bytesPerSecond: rate.downloadBytesPerSecond))  ↑ \(RateFormatter.string(bytesPerSecond: rate.uploadBytesPerSecond))"
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        statusItem.button?.toolTip = "Live traffic on the active network interface"
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
