import Darwin
import Foundation
import SystemConfiguration

struct NetworkInterfaceReader {
    func snapshot(at timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> TrafficSnapshot? {
        let primaryName = primaryInterfaceName()
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let first = addresses else { return nil }
        defer { freeifaddrs(first) }

        var candidates: [String: (received: UInt64, sent: UInt64)] = [:]
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            defer { cursor = current.pointee.ifa_next }
            let interface = current.pointee
            guard let address = interface.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_LINK),
                  interface.ifa_flags & UInt32(IFF_UP) != 0,
                  interface.ifa_flags & UInt32(IFF_RUNNING) != 0,
                  interface.ifa_flags & UInt32(IFF_LOOPBACK) == 0,
                  let data = interface.ifa_data else { continue }

            let name = String(cString: interface.ifa_name)
            let counters = data.assumingMemoryBound(to: if_data.self).pointee
            candidates[name] = (UInt64(counters.ifi_ibytes), UInt64(counters.ifi_obytes))
        }

        let selectedName: String?
        if let primaryName, candidates[primaryName] != nil {
            selectedName = primaryName
        } else {
            selectedName = candidates.keys.sorted { lhs, rhs in
                let lhsPhysical = lhs.hasPrefix("en")
                let rhsPhysical = rhs.hasPrefix("en")
                return lhsPhysical == rhsPhysical ? lhs < rhs : lhsPhysical
            }.first
        }

        guard let selectedName, let counters = candidates[selectedName] else { return nil }
        return TrafficSnapshot(
            interfaceName: selectedName,
            receivedBytes: counters.received,
            sentBytes: counters.sent,
            timestamp: timestamp
        )
    }

    private func primaryInterfaceName() -> String? {
        for key in ["State:/Network/Global/IPv4", "State:/Network/Global/IPv6"] {
            guard let properties = SCDynamicStoreCopyValue(nil, key as CFString) as? [String: Any],
                  let name = properties["PrimaryInterface"] as? String else { continue }
            return name
        }
        return nil
    }
}
