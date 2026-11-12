import Foundation

public struct TranscriptSegment: Identifiable, Equatable {
    public init(
        startTime: TimeInterval?,
        endTime: TimeInterval? = nil,
        text: AttributedString,
        isVolatile: Bool,
        words: [TimedWord] = [],
        speakerNumber: Int? = nil
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.isVolatile = isVolatile
        self.words = words
        self.speakerNumber = speakerNumber
    }

    public let id = UUID()
    public let startTime: TimeInterval?
    public let endTime: TimeInterval?
    public let text: AttributedString
    public let isVolatile: Bool
    public let words: [TimedWord]
    /// 話者分離で割り当てた話者の番号 (1 始まり)。未割り当てなら `nil`。
    public let speakerNumber: Int?
}
