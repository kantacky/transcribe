import Foundation

/// 認識結果の単語 (run) と、その音声上の時刻。
public struct TimedWord: Sendable, Equatable {
    public init(text: AttributedString, startTime: TimeInterval, endTime: TimeInterval) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
    }

    public let text: AttributedString
    public let startTime: TimeInterval
    public let endTime: TimeInterval
}
