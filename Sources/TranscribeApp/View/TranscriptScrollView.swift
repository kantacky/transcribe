import SwiftUI
import TranscribeDomain

struct TranscriptScrollView: View {
    let finalSegments: [TranscriptSegment]
    let volatileSegment: TranscriptSegment?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if finalSegments.isEmpty && volatileSegment == nil {
                        ContentUnavailableView(
                            "No transcript yet",
                            systemImage: "text.quote",
                            description: Text("Drop an audio file to start transcribing.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        ForEach(finalSegments) { segment in
                            TranscriptSegmentRow(segment: segment)
                        }

                        if let volatileSegment {
                            TranscriptSegmentRow(segment: volatileSegment)
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("transcript-bottom")
                }
                .font(.body)
                .lineSpacing(4)
                .padding()
            }
            .onChange(of: finalSegments) {
                scrollToBottom(proxy)
            }
            .onChange(of: volatileSegment) {
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("transcript-bottom", anchor: .bottom)
        }
    }
}
