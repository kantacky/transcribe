import ArgumentParser
import Testing

@testable import TranscribeCLI

@Suite
struct TranscribeCLIParsingTests {
    @Test
    func parsesAudioFilePathArgument() throws {
        let command = try TranscribeCLI.parse(["/tmp/sample.m4a"])

        #expect(command.audioFilePath == "/tmp/sample.m4a")
        #expect(command.localeIdentifier == nil)
    }

    @Test
    func parsesLocaleShortOption() throws {
        let command = try TranscribeCLI.parse(["/tmp/sample.m4a", "-l", "ja-JP"])

        #expect(command.localeIdentifier == "ja-JP")
    }

    @Test
    func parsesLocaleLongOption() throws {
        let command = try TranscribeCLI.parse(["--locale", "en-US", "/tmp/sample.m4a"])

        #expect(command.localeIdentifier == "en-US")
        #expect(command.audioFilePath == "/tmp/sample.m4a")
    }

    @Test
    func failsWhenAudioFilePathMissing() {
        #expect(throws: (any Error).self) {
            _ = try TranscribeCLI.parse([])
        }
    }

    @Test
    func runFailsWhenFileNotFound() async {
        var command = try! TranscribeCLI.parse(["/nonexistent/path/audio.m4a"])

        await #expect(throws: ValidationError.self) {
            try await command.run()
        }
    }
}

@Suite
struct TranscribeCLIDiarizationParsingTests {
    @Test
    func diarizationIsDisabledByDefault() throws {
        let command = try TranscribeCLI.parse(["/tmp/sample.m4a"])

        #expect(!command.diarize)
    }

    @Test
    func parsesDiarizationOptions() throws {
        let command = try TranscribeCLI.parse([
            "/tmp/sample.m4a", "--diarize", "--min-speakers", "2", "--max-speakers", "3",
        ])

        #expect(command.diarize)
        #expect(command.minSpeakers == 2)
        #expect(command.maxSpeakers == 3)
    }

    @Test
    func rejectsSpeakerCountWithoutDiarize() {
        #expect(throws: (any Error).self) {
            try TranscribeCLI.parse(["/tmp/sample.m4a", "--max-speakers", "2"])
        }
    }
}
