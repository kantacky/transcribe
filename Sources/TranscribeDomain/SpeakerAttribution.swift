import Foundation

/// 文字起こしの区間に話者分離の結果を対応付ける。
///
/// 文字起こしの 1 区間は話者の切り替わりをまたぐことがあるため、単語の時刻がある場合は
/// 単語ごとに話者を対応付け、話者が替わるところで区間を分ける。
public enum SpeakerAttribution {
    public static func attribute(
        _ segments: [TranscriptSegment],
        speakers: [SpeakerSegment]
    ) -> [TranscriptSegment] {
        guard !speakers.isEmpty else {
            return segments
        }

        return segments.flatMap { segment -> [TranscriptSegment] in
            guard !segment.words.isEmpty else {
                let speaker = segment.startTime.flatMap { start in
                    nearestSpeaker(from: start, to: segment.endTime ?? start, in: speakers)
                }
                return [segment.withSpeaker(speaker)]
            }

            var groups: [(speaker: Int?, words: [TimedWord])] = []
            for word in segment.words {
                let speaker = nearestSpeaker(from: word.startTime, to: word.endTime, in: speakers)
                if let last = groups.last, last.speaker == speaker {
                    groups[groups.count - 1].words.append(word)
                } else {
                    groups.append((speaker, [word]))
                }
            }

            guard groups.count > 1 else {
                return [segment.withSpeaker(groups.first?.speaker)]
            }

            return groups.map { group in
                var text = AttributedString()
                for word in group.words {
                    text.append(word.text)
                }
                return TranscriptSegment(
                    startTime: group.words.first?.startTime,
                    endTime: group.words.last?.endTime,
                    text: text,
                    isVolatile: segment.isVolatile,
                    words: group.words,
                    speakerNumber: group.speaker
                )
            }
        }
    }

    /// 区間と最も長く重なる話者。重なりがなければ区間の中心に最も近い話者。
    static func nearestSpeaker(
        from start: TimeInterval,
        to end: TimeInterval,
        in speakers: [SpeakerSegment]
    ) -> Int? {
        var overlaps: [Int: TimeInterval] = [:]
        for speaker in speakers {
            let overlap = min(end, speaker.endTime) - max(start, speaker.startTime)
            if overlap > 0 {
                overlaps[speaker.speakerNumber, default: 0] += overlap
            }
        }

        if let best = overlaps.max(by: { $0.value < $1.value }) {
            return best.key
        }

        let center = (start + end) / 2
        return speakers.min { distance(center, $0) < distance(center, $1) }?.speakerNumber
    }

    private static func distance(_ time: TimeInterval, _ segment: SpeakerSegment) -> TimeInterval {
        if time < segment.startTime { return segment.startTime - time }
        if time > segment.endTime { return time - segment.endTime }
        return 0
    }
}

extension TranscriptSegment {
    fileprivate func withSpeaker(_ speakerNumber: Int?) -> TranscriptSegment {
        TranscriptSegment(
            startTime: startTime,
            endTime: endTime,
            text: text,
            isVolatile: isVolatile,
            words: words,
            speakerNumber: speakerNumber
        )
    }
}
