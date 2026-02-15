import SwiftUI
import PencilKit

// MARK: - PencilKit Canvas Wrapper

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .label, width: 3)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

// MARK: - Signature Capture View

struct SignatureCaptureView: View {
    @Binding var signatureData: Data?
    @Binding var cfiNumber: String

    @State private var canvasView = PKCanvasView()
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
                    SignatureCanvasView(canvasView: $canvasView)
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
                        canvasView.drawing = PKDrawing()
                        hasDrawn = false
                        signatureData = nil
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

    private func captureSignature() {
        let image = canvasView.drawing.image(
            from: canvasView.bounds,
            scale: UIScreen.main.scale
        )
        signatureData = image.pngData()
        hasDrawn = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
