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
            converter?.primeMethod = .none  // Sacrifice quality of first samples in order to avoid any timestamp drift from source
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
        let bufferProcessed = Mutex(false)

        let status = converter.convert(to: conversionBuffer, error: &nsError) {
            packetCount, inputStatusPointer in
            let shouldProvideBuffer = bufferProcessed.withLock { bufferProcessed in
                guard !bufferProcessed else {
                    return false
                }

                bufferProcessed = true
                return true
            }

            inputStatusPointer.pointee = shouldProvideBuffer ? .haveData : .noDataNow
            return shouldProvideBuffer ? buffer : nil
        }

        guard status != .error else {
            throw Error.conversionFailed(nsError)
        }

        return conversionBuffer
    }
}
