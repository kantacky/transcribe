import Foundation

public struct TranscriptionResult: Sendable {
    public enum Kind: Sendable {
        case volatile
        case final
    }

    public init(text: AttributedString, kind: Kind, startTime: TimeInterval?) {
        self.text = text
        self.kind = kind
        self.startTime = startTime
    }

    public let text: AttributedString
    public let kind: Kind
    public let startTime: TimeInterval?
}
