import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ControllerView: View {
    @ObservedObject var client: MPCClient
    @State private var sensitivity: Double = 1.2
    @State private var lastTranslation: CGSize = .zero
    @State private var keyboardText = ""
    @State private var showingControlsSheet = false

    var body: some View {
        VStack(spacing: 12) {
            connectionHeader

            trackpadSurface
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
            .padding(.bottom, 14)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingControlsSheet) {
            controlsSheet
                .presentationDetents([.medium, .large])
        }
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
            Button("Controls") {
                showingControlsSheet = true
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))
        }
        .padding(.horizontal)
        .padding(.top, 10)
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
                    Text("Drag: move • Double tap: left click • Two-finger tap: right click")
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

    private var controlsSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pointer Sensitivity")
                        .font(.headline)
                    Slider(value: $sensitivity, in: 0.2...3.0, step: 0.1)
                    Text(String(format: "%.1fx", sensitivity))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Keyboard")
                        .font(.headline)

                    HStack(spacing: 8) {
                        TextField("Type and press Send", text: $keyboardText)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.send)
                            .onSubmit {
                                sendKeyboardText()
                            }

                        Button("Send") {
                            sendKeyboardText()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(keyboardText.isEmpty)
                    }

                    HStack(spacing: 12) {
                        Button("Enter") {
                            tapSpecialKey(code: 36)
                        }
                        .buttonStyle(.bordered)

                        Button("Backspace") {
                            tapSpecialKey(code: 51)
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.caption)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Controls")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingControlsSheet = false
                    }
                }
            }
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

    private func sendKeyboardText() {
        guard !keyboardText.isEmpty else { return }
        client.send(.keyboardText(keyboardText), mode: .reliable)
        keyboardText = ""
    }

    private func tapSpecialKey(code: UInt16) {
        client.send(.keyboardKey(code: code, isDown: true), mode: .reliable)
        client.send(.keyboardKey(code: code, isDown: false), mode: .reliable)
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
