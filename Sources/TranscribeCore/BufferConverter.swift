@preconcurrency import AVFoundation
import Foundation
import Synchronization

final class BufferConverter {
    enum Error: Swift.Error {
        case failedToCreateConverter
        case failedToCreateConversionBuffer
        case conversionFailed(NSError?)
    }

    private var converter: AVAudioConverter?
    func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws
        -> AVAudioPCMBuffer
    {
        let inputFormat = buffer.format
        guard inputFormat != format else {
            return buffer
        }

        if converter == nil || converter?.outputFormat != format {
            converter = AVAudioConverter(from: inputFormat, to: format)
            // Sacrifice quality of first samples in order to avoid any timestamp drift from source
            converter?.primeMethod = .none
        }

        guard let converter else {
            throw Error.failedToCreateConverter
        }

        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))
        guard
            let conversionBuffer = AVAudioPCMBuffer(
                pcmFormat: converter.outputFormat, frameCapacity: frameCapacity)
        else {
            throw Error.failedToCreateConversionBuffer
        }

        var nsError: NSError?
        let bufferProcessed = ProcessedFlag()

        let status = converter.convert(to: conversionBuffer, error: &nsError) {
            packetCount, inputStatusPointer in
            let shouldProvideBuffer = bufferProcessed.markIfNeeded()

            inputStatusPointer.pointee = shouldProvideBuffer ? .haveData : .noDataNow
            return shouldProvideBuffer ? buffer : nil
        }

        guard status != .error else {
            throw Error.conversionFailed(nsError)
        }

        return conversionBuffer
    }
}

/// Reference wrapper so the noncopyable `Atomic` isn't captured by value in an escaping closure.
private final class ProcessedFlag: Sendable {
    private let value = Atomic(false)

    /// Returns `true` the first time it is called, `false` afterwards.
    func markIfNeeded() -> Bool {
        value.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged
    }
}
