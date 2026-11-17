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

            VStack(alignment: .leading, spacing: 2) {
                if let speakerNumber = segment.speakerNumber {
                    Text("Speaker \(speakerNumber)", bundle: .module)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Self.color(for: speakerNumber))
                }

                Text(segment.text)
                    .foregroundStyle(segment.isVolatile ? .secondary : .primary)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private static let speakerColors: [Color] = [.blue, .orange, .green, .purple, .pink, .teal]

    private static func color(for speakerNumber: Int) -> Color {
        speakerColors[(max(speakerNumber, 1) - 1) % speakerColors.count]
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
