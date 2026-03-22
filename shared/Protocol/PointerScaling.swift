import CoreGraphics
import Foundation

enum PointerScaling {
    static func normalizedDelta(
        rawDelta: CGSize,
        surfaceSize: CGSize,
        sensitivity: Double
    ) -> (x: Double, y: Double) {
        let width = max(surfaceSize.width, 1)
        let height = max(surfaceSize.height, 1)
        let normalizedX = (rawDelta.width / width) * 1400
        let normalizedY = (rawDelta.height / height) * 1400
        return (x: normalizedX * sensitivity, y: normalizedY * sensitivity)
    }
}
