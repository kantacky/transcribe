import SwiftUI

struct TranscriptionView: View {
    @State private var model = TranscriptionViewModel()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Spacer()

                    Button("Export Text", systemImage: "square.and.arrow.down", action: model.showExporter)
                        .disabled(!model.canExportTranscript)
                }

                AudioDropZone(
                    fileName: model.fileName,
                    isTargeted: model.isDropTargeted,
                    isTranscribing: model.isTranscribing,
                    transcriptionProgress: model.transcriptionProgress,
                    selectedLocale: model.selectedLocale,
                    supportedLocales: model.supportedLocales,
                    status: model.statusMessage,
                    onSelectLocale: model.selectLocale,
                    onSelectFile: model.selectAudioFile
                )
            }
            .padding()

            Divider()

            TranscriptScrollView(
                finalSegments: model.finalSegments,
                volatileSegment: model.volatileSegment
            )
        }
        .frame(minWidth: 640, minHeight: 460)
        .dropDestination(for: URL.self) { urls, _ in
            model.handleDroppedURLs(urls)
        } isTargeted: { isTargeted in
            model.isDropTargeted = isTargeted
        }
        .alert("Transcription failed", isPresented: $model.isShowingError) {
            Button("OK", role: .cancel) {
                model.dismissError()
            }
        } message: {
            Text(model.errorMessage)
        }
        .task {
            await model.loadSupportedLocales()
        }
        .fileExporter(
            isPresented: $model.isShowingExporter,
            document: model.exportDocument,
            contentType: .plainText,
            defaultFilename: model.exportFileName
        ) { result in
            model.finishExport()

            if case let .failure(error) = result {
                model.showExportError(error)
            }
        }
    }
}

#Preview {
    TranscriptionView()
}
