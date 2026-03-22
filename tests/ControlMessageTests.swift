import XCTest
@testable import RemotePointerShared

final class ControlMessageTests: XCTestCase {
    func testMoveRoundTrip() throws {
        let message = ControlMessage.move(deltaX: 12.4, deltaY: -9.8, timestamp: 42)
        let encoded = try ControlCodec.encode(message)
        let decoded = try ControlCodec.decode(encoded)

        guard case let .move(deltaX, deltaY, timestamp) = decoded else {
            XCTFail("Expected move message")
            return
        }

        XCTAssertEqual(deltaX, 12.4, accuracy: 0.001)
        XCTAssertEqual(deltaY, -9.8, accuracy: 0.001)
        XCTAssertEqual(timestamp, 42, accuracy: 0.001)
    }
}
