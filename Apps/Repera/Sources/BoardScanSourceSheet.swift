import SwiftUI
import UIKit

/// Modal compacto para elegir cámara o galería (no Menu/popover).
struct BoardScanSourceSheet: View {
    @Environment(\.dismiss) private var dismiss

    var onCamera: () -> Void
    var onLibrary: () -> Void

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OGPageHeader(title: "Escanear pizarra", subtitle: "Cámara o galería") {
                CloseToolbarButton(action: { dismiss() }, large: true)
            }
            .padding(.top, 4)

            VStack(spacing: 0) {
                if cameraAvailable {
                    Button {
                        dismiss()
                        DispatchQueue.main.async {
                            onCamera()
                        }
                    } label: {
                        sourceRow(
                            title: "Tomar foto",
                            subtitle: "Abrir la cámara",
                            systemName: "camera.fill",
                            tint: OG.accent
                        )
                    }
                    Divider().opacity(0.35).padding(.leading, 52)
                }
                Button {
                    dismiss()
                    DispatchQueue.main.async {
                        onLibrary()
                    }
                } label: {
                    sourceRow(
                        title: "Elegir de la galería",
                        subtitle: "Foto de pizarra o TV",
                        systemName: "photo.on.rectangle",
                        tint: OG.blue
                    )
                }
            }
            .background(OG.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: OG.radiusCard, style: .continuous))
        }
        .padding(.horizontal, OG.pad)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .ogFittedHeight()
        .ogFittedSheet()
    }

    private func sourceRow(
        title: String,
        subtitle: String,
        systemName: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(OG.label)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(OG.label2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
