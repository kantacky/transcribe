import Foundation

public struct TranscriptionResult: Sendable {
    public enum Kind: Sendable {
        case volatile
        case final
    }

    public init(
        text: AttributedString,
        kind: Kind,
        startTime: TimeInterval?,
        endTime: TimeInterval? = nil,
        words: [TimedWord] = []
    ) {
        self.text = text
        self.kind = kind
        self.startTime = startTime
        self.endTime = endTime
        self.words = words
    }

    public let text: AttributedString
    public let kind: Kind
    public let startTime: TimeInterval?
    public let endTime: TimeInterval?
    public let words: [TimedWord]
}
