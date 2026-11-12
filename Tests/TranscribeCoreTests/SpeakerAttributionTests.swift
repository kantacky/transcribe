import Foundation
import Testing
import TranscribeDomain

@testable import TranscribeCore

@Suite
struct SpeakerAttributionTests {
    private let speakers = [
        SpeakerSegment(speakerNumber: 1, startTime: 0, endTime: 5),
        SpeakerSegment(speakerNumber: 2, startTime: 5, endTime: 10),
    ]

    @Test
    func assignsSpeakerBySegmentOverlapWithoutWords() {
        let segments = [
            TranscriptSegment(startTime: 6, endTime: 9, text: "hello", isVolatile: false)
        ]

        let attributed = SpeakerAttribution.attribute(segments, speakers: speakers)

        #expect(attributed.map(\.speakerNumber) == [2])
    }

    @Test
    func splitsSegmentWhenSpeakerChangesMidway() {
        let words = [
            TimedWord(text: "Hi ", startTime: 1, endTime: 2),
            TimedWord(text: "there. ", startTime: 2, endTime: 3),
            TimedWord(text: "Hello.", startTime: 6, endTime: 7),
        ]
        let segments = [
            TranscriptSegment(
                startTime: 1, endTime: 7, text: "Hi there. Hello.", isVolatile: false,
                words: words)
        ]

        let attributed = SpeakerAttribution.attribute(segments, speakers: speakers)

        #expect(attributed.map(\.speakerNumber) == [1, 2])
        #expect(attributed.map { String($0.text.characters) } == ["Hi there. ", "Hello."])
        #expect(attributed.map(\.startTime) == [1, 6])
    }

    @Test
    func fallsBackToNearestSpeakerInGap() {
        let gapSpeakers = [
            SpeakerSegment(speakerNumber: 1, startTime: 0, endTime: 2),
            SpeakerSegment(speakerNumber: 2, startTime: 8, endTime: 10),
        ]
        let segments = [
            TranscriptSegment(startTime: 6.5, endTime: 7, text: "x", isVolatile: false)
        ]

        let attributed = SpeakerAttribution.attribute(segments, speakers: gapSpeakers)

        #expect(attributed.map(\.speakerNumber) == [2])
    }

    @Test
    func leavesSegmentsUntouchedWithoutSpeakers() {
        let segments = [
            TranscriptSegment(startTime: 1, text: "x", isVolatile: false)
        ]

        let attributed = SpeakerAttribution.attribute(segments, speakers: [])

        #expect(attributed == segments)
    }

    @Test
    func normalizesSpeakerIDsInOrderOfAppearance() {
        let normalized = SpeakerDiarizer.normalize([
            (id: "S7", start: 4, end: 6),
            (id: "S3", start: 0, end: 2),
            (id: "S7", start: 2, end: 4),
        ])

        #expect(normalized.map(\.speakerNumber) == [1, 2, 2])
    }
}
