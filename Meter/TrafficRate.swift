import Foundation

struct TrafficSnapshot: Equatable {
    let interfaceName: String
    let receivedBytes: UInt64
    let sentBytes: UInt64
    let timestamp: TimeInterval
}

struct TrafficRate: Equatable {
    let downloadBytesPerSecond: Double
    let uploadBytesPerSecond: Double

    static let zero = TrafficRate(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
}

struct TrafficRateCalculator {
    private var previous: TrafficSnapshot?

    mutating func calculate(_ snapshot: TrafficSnapshot) -> TrafficRate? {
        defer { previous = snapshot }
        guard let previous,
              previous.interfaceName == snapshot.interfaceName,
              snapshot.timestamp > previous.timestamp,
              snapshot.receivedBytes >= previous.receivedBytes,
              snapshot.sentBytes >= previous.sentBytes else {
            return nil
        }

        let elapsed = snapshot.timestamp - previous.timestamp
        return TrafficRate(
            downloadBytesPerSecond: Double(snapshot.receivedBytes - previous.receivedBytes) / elapsed,
            uploadBytesPerSecond: Double(snapshot.sentBytes - previous.sentBytes) / elapsed
        )
    }

    mutating func reset() {
        previous = nil
    }
}

enum RateFormatter {
    static func menuBarString(bytesPerSecond: Double) -> String {
        let value = max(0, bytesPerSecond)
        let scaled: Double
        let unit: String

        switch value {
        case 1_000_000_000...:
            scaled = value / 1_000_000_000
            unit = "G"
        case 1_000_000...:
            scaled = value / 1_000_000
            unit = "M"
        default:
            scaled = value / 1_000
            unit = "K"
        }

        return String(format: scaled < 10 ? "%.1f%@" : "%.0f%@", scaled, unit)
    }

    static func string(bytesPerSecond: Double) -> String {
        let value = max(0, bytesPerSecond)
        let unit: String
        let scaled: Double

        switch value {
        case 1_000_000_000...:
            unit = "GB/s"
            scaled = value / 1_000_000_000
        case 1_000_000...:
            unit = "MB/s"
            scaled = value / 1_000_000
        default:
            unit = "KB/s"
            scaled = value / 1_000
        }

        let precision = scaled < 10 ? 1 : 0
        return String(format: "%.*f %@", precision, scaled, unit)
    }
}
