import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ControllerView: View {
    @ObservedObject var client: MPCClient
    @State private var sensitivity: Double = 1.2
    @State private var lastTranslation: CGSize = .zero

    var body: some View {
        VStack(spacing: 16) {
            connectionHeader

            VStack(alignment: .leading, spacing: 8) {
                Text("Sensitivity")
                    .font(.headline)
                Slider(value: $sensitivity, in: 0.2...3.0, step: 0.1)
                Text(String(format: "%.1fx", sensitivity))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            trackpadSurface
                .padding(.horizontal)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, minHeight: 320)

            HStack(spacing: 12) {
                Button {
                    client.send(.click(button: .left), mode: .reliable)
                } label: {
                    Text("Left Click")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    client.send(.click(button: .right), mode: .reliable)
                } label: {
                    Text("Right Click")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var connectionHeader: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(client.isConnected ? .green : .orange)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(client.isConnected ? "Connected" : "Searching for host...")
                    .font(.headline)
                Text("Mac: \(client.connectedPeerName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    private var trackpadSurface: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .contentShape(Rectangle())
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.secondary.opacity(0.4), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Text("Drag to move pointer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
                .overlay {
                    TrackpadTapCaptureView(
                        onLeftDoubleTap: {
                            client.send(.click(button: .left), mode: .reliable)
                        },
                        onTwoFingerTap: {
                            client.send(.click(button: .right), mode: .reliable)
                        }
                    )
                }
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            sendDelta(from: value.translation, in: geometry.size)
                        }
                        .onEnded { _ in
                            lastTranslation = .zero
                        }
                )
        }
    }

    private func sendDelta(from translation: CGSize, in surfaceSize: CGSize) {
        let rawDeltaX = translation.width - lastTranslation.width
        let rawDeltaY = translation.height - lastTranslation.height
        lastTranslation = translation

        guard rawDeltaX != 0 || rawDeltaY != 0 else { return }

        let scaled = PointerScaling.normalizedDelta(
            rawDelta: CGSize(width: rawDeltaX, height: rawDeltaY),
            surfaceSize: surfaceSize,
            sensitivity: sensitivity
        )

        let message = ControlMessage.move(
            deltaX: scaled.x,
            deltaY: scaled.y,
            timestamp: Date().timeIntervalSince1970
        )
        client.send(message, mode: .unreliable)
    }
}

#if canImport(UIKit)
private struct TrackpadTapCaptureView: UIViewRepresentable {
    let onLeftDoubleTap: () -> Void
    let onTwoFingerTap: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let leftDoubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLeftDoubleTap))
        leftDoubleTap.numberOfTapsRequired = 2
        leftDoubleTap.numberOfTouchesRequired = 1
        leftDoubleTap.cancelsTouchesInView = false

        let twoFingerTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerTap))
        twoFingerTap.numberOfTapsRequired = 1
        twoFingerTap.numberOfTouchesRequired = 2
        twoFingerTap.cancelsTouchesInView = false

        leftDoubleTap.require(toFail: twoFingerTap)

        view.addGestureRecognizer(leftDoubleTap)
        view.addGestureRecognizer(twoFingerTap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onLeftDoubleTap: onLeftDoubleTap, onTwoFingerTap: onTwoFingerTap)
    }

    final class Coordinator: NSObject {
        private let onLeftDoubleTap: () -> Void
        private let onTwoFingerTap: () -> Void

        init(onLeftDoubleTap: @escaping () -> Void, onTwoFingerTap: @escaping () -> Void) {
            self.onLeftDoubleTap = onLeftDoubleTap
            self.onTwoFingerTap = onTwoFingerTap
        }

        @objc func handleLeftDoubleTap() {
            onLeftDoubleTap()
        }

        @objc func handleTwoFingerTap() {
            onTwoFingerTap()
        }
    }
}
#endif
