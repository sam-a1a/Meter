import XCTest
@testable import Meter

final class TrafficRateTests: XCTestCase {
    func testCalculatesBytesPerSecondUsingElapsedTime() {
        var calculator = TrafficRateCalculator()
        XCTAssertNil(calculator.calculate(snapshot("en0", received: 1_000, sent: 2_000, time: 10)))
        let rate = calculator.calculate(snapshot("en0", received: 4_000, sent: 3_000, time: 12))
        XCTAssertEqual(rate?.downloadBytesPerSecond, 1_500)
        XCTAssertEqual(rate?.uploadBytesPerSecond, 500)
    }

    func testInterfaceChangeAndCounterResetDoNotCreateSpikes() {
        var calculator = TrafficRateCalculator()
        XCTAssertNil(calculator.calculate(snapshot("en0", received: 100, sent: 100, time: 1)))
        XCTAssertNil(calculator.calculate(snapshot("utun0", received: 500, sent: 500, time: 2)))
        XCTAssertEqual(calculator.calculate(snapshot("utun0", received: 600, sent: 700, time: 3))?.uploadBytesPerSecond, 200)
        XCTAssertNil(calculator.calculate(snapshot("utun0", received: 10, sent: 10, time: 4)))
        XCTAssertEqual(calculator.calculate(snapshot("utun0", received: 20, sent: 30, time: 5))?.downloadBytesPerSecond, 10)
    }

    func testFormatsDecimalRateUnits() {
        XCTAssertEqual(RateFormatter.string(bytesPerSecond: 0), "0.0 KB/s")
        XCTAssertEqual(RateFormatter.string(bytesPerSecond: 12_500), "12 KB/s")
        XCTAssertEqual(RateFormatter.string(bytesPerSecond: 1_500_000), "1.5 MB/s")
    }

    private func snapshot(_ name: String, received: UInt64, sent: UInt64, time: TimeInterval) -> TrafficSnapshot {
        TrafficSnapshot(interfaceName: name, receivedBytes: received, sentBytes: sent, timestamp: time)
    }
}
