import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class MeterState {
    var rate: TrafficRate = .zero
    var interfaceName: String?
    var launchAtLoginEnabled = SMAppService.mainApp.status == .enabled

    func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }
}
