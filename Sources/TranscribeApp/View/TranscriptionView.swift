import SwiftUI

struct TranscriptionView: View {
    @State private var model = TranscriptionViewModel()

    var body: some View {
        NavigationSplitView {
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
            .toolbar {
                ToolbarItem {
                    Button(
                        "Export Text", systemImage: "square.and.arrow.down",
                        action: model.showExporter
                    )
                    .disabled(!model.canExportTranscript)
                }
            }
            .padding()
            .navigationSplitViewColumnWidth(300)
        } detail: {
            TranscriptScrollView(
                finalSegments: model.finalSegments,
                volatileSegment: model.volatileSegment
            )
        }
        .frame(minWidth: 800, minHeight: 600)
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

            if case .failure(let error) = result {
                model.showExportError(error)
            }
        }
    }
}

#Preview {
    TranscriptionView()
}
