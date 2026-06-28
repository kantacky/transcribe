import SwiftUI
import TranscribeDomain

struct TranscriptSegmentRow: View {
    let segment: TranscriptSegment

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(formattedTimestamp)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .trailing)
                .textSelection(.enabled)

            Text(segment.text)
                .foregroundStyle(segment.isVolatile ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formattedTimestamp: String {
        guard let startTime = segment.startTime, startTime.isFinite else {
            return "--:--"
        }

        let totalSeconds = max(0, Int(startTime.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return "\(minutes):\(seconds.formatted(.number.precision(.integerLength(2))))"
    }
}
