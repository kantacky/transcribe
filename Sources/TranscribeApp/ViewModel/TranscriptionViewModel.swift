import AVFoundation
import Foundation
import Observation
import TranscribeCore
import TranscribeDomain
import TranscribeExport

@MainActor
@Observable
final class TranscriptionViewModel {
    var finalSegments: [TranscriptSegment] = []
    var volatileSegment: TranscriptSegment?
    var fileName: String?
    var isDropTargeted = false
    var isShowingError = false
    var errorMessage = ""
    var selectedLocale: Locale?
    var supportedLocales: [Locale] = []
    var isShowingExporter = false
    var exportFileName = TranscriptTextExporter.fileName(for: nil)
    var exportDocument = TranscriptTextDocument()

    private(set) var isTranscribing = false
    private(set) var transcriptionProgress = 0.0
    private var transcriptionTask: Task<Void, Never>?
    private var audioDuration: TimeInterval?

    var canExportTranscript: Bool {
        !finalSegments.isEmpty
    }

    var statusMessage: String {
        if isTranscribing {
            "Transcribing..."
        } else if supportedLocales.isEmpty {
            "Loading supported languages..."
        } else {
            "Drop an audio file here to transcribe it in real time."
        }
    }

    func loadSupportedLocales() async {
        let locales = await Transcriber.supportedLocales
        supportedLocales = locales.sorted {
            localizedName(for: $0) < localizedName(for: $1)
        }

        selectedLocale = supportedLocales.first { locale in
            locale.identifier(.bcp47) == Locale.current.identifier(.bcp47)
        } ?? supportedLocales.first { locale in
            locale.identifier(.bcp47) == "en-US"
        } ?? supportedLocales.first
    }

    func selectLocale(_ locale: Locale) {
        selectedLocale = locale
    }

    func handleDroppedURLs(_ urls: [URL]) -> Bool {
        guard let url = urls.first else {
            return false
        }

        selectAudioFile(url)
        return true
    }

    func selectAudioFile(_ url: URL) {
        transcriptionTask?.cancel()
        transcriptionTask = Task {
            await transcribe(url)
        }
    }

    func dismissError() {
        errorMessage = ""
        isShowingError = false
    }

    func showExporter() {
        exportFileName = TranscriptTextExporter.fileName(for: fileName)
        exportDocument = TranscriptTextExporter.document(for: finalSegments)
        isShowingExporter = true
    }

    func finishExport() {
        isShowingExporter = false
    }

    func showExportError(_ error: Error) {
        show(error)
    }

    private func transcribe(_ url: URL) async {
        resetTranscript(for: url)

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            audioDuration = try audioDuration(for: url)

            guard let selectedLocale else {
                throw TranscriptionError.localeNotSupported
            }

            let transcriber = Transcriber(locale: selectedLocale)
            let resultStream = try await transcriber.transcribe(audioFileURL: url)

            for try await result in resultStream {
                if Task.isCancelled {
                    break
                }

                apply(result)
            }
        } catch is CancellationError {
            return
        } catch {
            show(error)
        }

        isTranscribing = false
        transcriptionProgress = 1
        volatileSegment = nil
    }

    private func resetTranscript(for url: URL) {
        fileName = url.lastPathComponent
        finalSegments = []
        volatileSegment = nil
        errorMessage = ""
        isShowingError = false
        isTranscribing = true
        transcriptionProgress = 0
        audioDuration = nil
    }

    private func apply(_ result: TranscriptionResult) {
        updateProgress(with: result.startTime)

        switch result.kind {
        case .final:
            finalSegments.append(
                TranscriptSegment(
                    startTime: result.startTime,
                    text: result.text,
                    isVolatile: false
                )
            )
            volatileSegment = nil
        case .volatile:
            volatileSegment = TranscriptSegment(
                startTime: result.startTime,
                text: result.text,
                isVolatile: true
            )
        }
    }

    private func show(_ error: Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }

    private func localizedName(for locale: Locale) -> String {
        locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
    }

    private func audioDuration(for url: URL) throws -> TimeInterval {
        let audioFile = try AVAudioFile(forReading: url)
        let sampleRate = audioFile.processingFormat.sampleRate

        guard sampleRate > 0 else {
            return 0
        }

        return TimeInterval(audioFile.length) / sampleRate
    }

    private func updateProgress(with timestamp: TimeInterval?) {
        guard
            let timestamp,
            let audioDuration,
            audioDuration > 0
        else {
            return
        }

        let progress = min(max(timestamp / audioDuration, 0), 1)
        transcriptionProgress = max(transcriptionProgress, progress)
    }

}
