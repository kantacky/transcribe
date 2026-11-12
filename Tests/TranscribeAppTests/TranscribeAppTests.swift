import Testing
import TranscribeDomain
import TranscribeExport

@testable import TranscribeApp

@Suite
struct TranscribeAppTests {
    @MainActor
    @Test
    func showExporterSnapshotsCurrentTranscript() {
        let model = TranscriptionViewModel()
        model.fileName = "meeting.m4a"
        model.finalSegments = [
            TranscriptSegment(
                startTime: 1,
                text: AttributedString("hello"),
                isVolatile: false
            )
        ]

        model.showExporter()

        #expect(model.isShowingExporter)
        #expect(model.exportFileName == "meeting.txt")
        #expect(model.exportDocument.text == "[0:01] hello")
    }

    @MainActor
    @Test
    func finishExportDismissesExporter() {
        let model = TranscriptionViewModel()
        model.finalSegments = [
            TranscriptSegment(
                startTime: nil,
                text: AttributedString("hello"),
                isVolatile: false
            )
        ]
        model.showExporter()

        model.finishExport()

        #expect(!model.isShowingExporter)
    }

    @Test
    func exportingTranscriptWithOutOfRangeTimestampDoesNotCrash() {
        let segments = [
            TranscriptSegment(
                startTime: .greatestFiniteMagnitude,
                text: AttributedString("hello"),
                isVolatile: false
            )
        ]

        let document = TranscriptTextExporter.document(for: segments)

        #expect(document.text == "[--:--] hello")
    }

    @Test
    func exportedTextIncludesSpeakerNumber() {
        let segments = [
            TranscriptSegment(
                startTime: 65,
                text: "hello",
                isVolatile: false,
                speakerNumber: 2
            )
        ]

        let text = TranscriptTextExporter.text(for: segments)

        #expect(text == "[1:05] Speaker 2: hello")
    }
}
