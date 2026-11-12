import Foundation

/// 話者分離で得られた 1 区間。`speakerNumber` は最初に話した順に 1 から振った番号。
public struct SpeakerSegment: Sendable, Equatable {
    public init(speakerNumber: Int, startTime: TimeInterval, endTime: TimeInterval) {
        self.speakerNumber = speakerNumber
        self.startTime = startTime
        self.endTime = endTime
    }

    public let speakerNumber: Int
    public let startTime: TimeInterval
    public let endTime: TimeInterval
}
