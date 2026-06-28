import Foundation

public struct TranscriptSegment: Identifiable, Equatable {
    public init(
        startTime: TimeInterval?,
        text: AttributedString,
        isVolatile: Bool
    ) {
        self.startTime = startTime
        self.text = text
        self.isVolatile = isVolatile
    }

    public let id = UUID()
    public let startTime: TimeInterval?
    public let text: AttributedString
    public let isVolatile: Bool
}
