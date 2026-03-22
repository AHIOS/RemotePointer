import CoreGraphics
import XCTest
@testable import RemotePointerShared

final class PointerScalingTests: XCTestCase {
    func testScalingNormalizesBySurfaceAndSensitivity() {
        let result = PointerScaling.normalizedDelta(
            rawDelta: CGSize(width: 50, height: 25),
            surfaceSize: CGSize(width: 200, height: 100),
            sensitivity: 2.0
        )

        XCTAssertEqual(result.x, 700, accuracy: 0.001)
        XCTAssertEqual(result.y, -700, accuracy: 0.001)
    }
}
