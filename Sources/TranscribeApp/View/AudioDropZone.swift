import SwiftUI

struct AudioDropZone: View {
    let fileName: String?
    let isTargeted: Bool
    let isTranscribing: Bool
    let transcriptionProgress: Double
    let selectedLocale: Locale?
    let supportedLocales: [Locale]
    let status: String
    let onSelectLocale: (Locale) -> Void
    let onSelectFile: (URL) -> Void

    @State private var isShowingFileImporter = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isTargeted ? "waveform.badge.magnifyingglass" : "waveform")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)

            Text(fileName ?? "Drop an audio file")
                .font(.headline)

            if isTranscribing {
                ProgressView(value: transcriptionProgress, total: 1) {
                    Text(status)
                } currentValueLabel: {
                    Text(
                        transcriptionProgress,
                        format: .percent.precision(.fractionLength(0))
                    )
                }
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .frame(maxWidth: 260)
            } else {
                Text(status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Picker("Language", selection: selectedLocaleBinding) {
                ForEach(supportedLocales, id: \.identifier) { locale in
                    Text(locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier)
                        .tag(Optional(locale))
                }
            }
            .frame(maxWidth: 260)
            .disabled(supportedLocales.isEmpty)

            Button("Choose Audio File", systemImage: "folder", action: showFileImporter)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                )
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result, let url = urls.first {
                onSelectFile(url)
            }
        }
    }

    private func showFileImporter() {
        isShowingFileImporter = true
    }

    private var selectedLocaleBinding: Binding<Locale?> {
        Binding {
            selectedLocale
        } set: { locale in
            if let locale {
                onSelectLocale(locale)
            }
        }
    }
}
