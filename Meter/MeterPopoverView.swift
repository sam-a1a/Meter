import AppKit
import SwiftUI

struct MeterPopoverView: View {
    let state: MeterState
    @State private var loginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "speedometer")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.tint)
                    .frame(width: 38, height: 38)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Meter")
                        .font(.headline)
                    Text("Live network traffic")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                rateCard(
                    label: "DOWNLOAD",
                    symbol: "arrow.down",
                    color: .blue,
                    value: state.rate.downloadBytesPerSecond
                )
                rateCard(
                    label: "UPLOAD",
                    symbol: "arrow.up",
                    color: .mint,
                    value: state.rate.uploadBytesPerSecond
                )
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(state.interfaceName == nil ? Color.secondary : Color.green)
                        .frame(width: 7, height: 7)
                    Text(state.interfaceName.map { "Active interface: \($0)" } ?? "Waiting for a network connection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Traffic used by this Mac, updated every second. This is not an internet speed test.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Toggle("Launch at login", isOn: Binding(
                get: { state.launchAtLoginEnabled },
                set: { enabled in
                    do {
                        try state.setLaunchAtLogin(enabled)
                    } catch {
                        loginError = error.localizedDescription
                    }
                }
            ))
            .toggleStyle(.switch)

            HStack {
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Quit Meter") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
            }
        }
        .padding(18)
        .frame(width: 340)
        .alert("Could not change login setting", isPresented: Binding(
            get: { loginError != nil },
            set: { if !$0 { loginError = nil } }
        )) {
            Button("OK") { loginError = nil }
        } message: {
            Text(loginError ?? "")
        }
    }

    private func rateCard(label: String, symbol: String, color: Color, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                Text(label)
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(color)

            Text(RateFormatter.string(bytesPerSecond: value))
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}
