import AVFoundation
import Testing

@testable import TranscribeCore

@Suite
struct BufferConverterTests {
    @Test
    func returnsSameBufferWhenFormatsMatch() throws {
        let converter = BufferConverter()
        let format = AVAudioFormat(
            standardFormatWithSampleRate: 16_000,
            channels: 1
        )!
        let buffer = makeBuffer(format: format, frameCount: 1_024)

        let converted = try converter.convertBuffer(buffer, to: format)

        #expect(converted === buffer)
    }

    @Test
    func convertsToDifferentSampleRate() throws {
        let converter = BufferConverter()
        let inputFormat = AVAudioFormat(
            standardFormatWithSampleRate: 48_000,
            channels: 1
        )!
        let outputFormat = AVAudioFormat(
            standardFormatWithSampleRate: 16_000,
            channels: 1
        )!
        let buffer = makeBuffer(format: inputFormat, frameCount: 4_800)

        let converted = try converter.convertBuffer(buffer, to: outputFormat)

        #expect(converted !== buffer)
        #expect(converted.format.sampleRate == 16_000)
        #expect(converted.frameLength > 0)
        #expect(converted.frameLength <= 1_600)
    }

    @Test
    func reusesConverterAcrossCallsWithSameOutputFormat() throws {
        let converter = BufferConverter()
        let inputFormat = AVAudioFormat(
            standardFormatWithSampleRate: 48_000,
            channels: 1
        )!
        let outputFormat = AVAudioFormat(
            standardFormatWithSampleRate: 16_000,
            channels: 1
        )!

        let first = try converter.convertBuffer(
            makeBuffer(format: inputFormat, frameCount: 4_800),
            to: outputFormat
        )
        let second = try converter.convertBuffer(
            makeBuffer(format: inputFormat, frameCount: 4_800),
            to: outputFormat
        )

        #expect(first.format.sampleRate == second.format.sampleRate)
    }

    private func makeBuffer(
        format: AVAudioFormat,
        frameCount: AVAudioFrameCount
    ) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        if let channelData = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                let samples = channelData[channel]
                for index in 0..<Int(frameCount) {
                    samples[index] = sinf(Float(index) * 0.01)
                }
            }
        }
        return buffer
    }
}
