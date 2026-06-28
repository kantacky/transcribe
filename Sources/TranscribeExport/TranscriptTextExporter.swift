import Foundation
import TranscribeDomain

public enum TranscriptTextExporter {
    public static func fileName(for sourceFileName: String?) -> String {
        let baseName =
            sourceFileName.map {
                URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent
            } ?? "Transcript"

        return "\(baseName).txt"
    }

    public static func document(for segments: [TranscriptSegment]) -> TranscriptTextDocument {
        TranscriptTextDocument(text: text(for: segments))
    }

    public static func text(for segments: [TranscriptSegment]) -> String {
        segments
            .map { segment in
                "[\(formatTimestamp(segment.startTime))] \(String(segment.text.characters[...]))"
            }
            .joined(separator: "\n")
    }

    private static func formatTimestamp(_ time: TimeInterval?) -> String {
        guard
            let time,
            time.isFinite,
            time < TimeInterval(Int.max)
        else {
            return "--:--"
        }

        let totalSeconds = max(0, Int(time.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return "\(minutes):\(seconds.formatted(.number.precision(.integerLength(2))))"
    }
}
