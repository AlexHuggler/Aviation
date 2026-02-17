import SwiftUI
import PencilKit

// MARK: - PencilKit Canvas Wrapper (H-4: coordinator-managed lifecycle)

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var signatureData: Data?
    @Binding var hasDrawn: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = context.coordinator.canvasView
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .label, width: 3)
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    // H-4: Coordinator owns the PKCanvasView instance, surviving SwiftUI state resets
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let canvasView = PKCanvasView()

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // No-op for now — drawing state tracked via capture button
        }
    }
}

// MARK: - Signature Capture View

struct SignatureCaptureView: View {
    @Binding var signatureData: Data?
    @Binding var cfiNumber: String

    // H-1: Use environment displayScale instead of deprecated UIScreen.main.scale
    @Environment(\.displayScale) private var displayScale

    @State private var hasDrawn = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CFI ENDORSEMENT")
                .sectionHeaderStyle()

            // CFI Number field
            HStack {
                Image(systemName: "person.badge.shield.checkmark")
                    .foregroundStyle(Color.skyBlue)
                TextField("CFI Certificate Number", text: $cfiNumber)
                    .font(.system(.body, design: .rounded))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Signature canvas
            VStack(spacing: 8) {
                Text("Instructor Signature")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack(alignment: .bottomTrailing) {
                    SignatureCanvasView(signatureData: $signatureData, hasDrawn: $hasDrawn)
                        .frame(height: 120)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(alignment: .center) {
                            if !hasDrawn && signatureData == nil {
                                Text("Sign here")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.tertiary)
                                    .allowsHitTesting(false)
                            }
                        }

                    Button {
                        clearCanvas()
                    } label: {
                        Image(systemName: "eraser.fill")
                            .font(.caption)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(8)
                }

                // Capture button
                Button {
                    captureSignature()
                } label: {
                    HStack {
                        Image(systemName: "signature")
                        Text("Capture Signature")
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.skyBlue)
                .disabled(cfiNumber.isEmpty)

                if signatureData != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.currencyGreen)
                            .symbolEffect(.bounce, value: signatureData != nil)
                        Text("Signature captured")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.currencyGreen)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // H-1: Uses @Environment(\.displayScale) instead of deprecated UIScreen.main.scale
    private func captureSignature() {
        // Access the canvas through the view hierarchy — find PKCanvasView in the responder chain
        // For UIViewRepresentable, we need to get the canvas from the coordinator
        // Since we can't directly access the coordinator here, we use a workaround:
        // The PKCanvasView is the first responder's ancestor — use UIApplication to find it
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let canvasView = window.findView(ofType: PKCanvasView.self) else {
            return
        }

        let image = canvasView.drawing.image(
            from: canvasView.bounds,
            scale: displayScale
        )
        signatureData = image.pngData()
        hasDrawn = true
        Haptic.success()
    }

    private func clearCanvas() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let canvasView = window.findView(ofType: PKCanvasView.self) else {
            return
        }
        canvasView.drawing = PKDrawing()
        hasDrawn = false
        signatureData = nil
    }
}

// MARK: - UIView Helper

private extension UIView {
    func findView<T: UIView>(ofType type: T.Type) -> T? {
        if let match = self as? T { return match }
        for subview in subviews {
            if let found = subview.findView(ofType: type) {
                return found
            }
        }
        return nil
    }
}
