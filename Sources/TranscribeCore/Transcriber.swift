import AVFoundation
import Speech
import TranscribeDomain

public final actor Transcriber {
    private let locale: Locale
    private let converter = BufferConverter()

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public static var supportedLocales: [Locale] {
        get async {
            await SpeechTranscriber.supportedLocales
        }
    }

    public func transcribe(
        audioFileURL: URL
    ) async throws -> AsyncThrowingStream<TranscriptionResult, Error> {
        let audioBuffers = try audioBuffers(from: audioFileURL)
        return try await transcribe(audioBuffers: audioBuffers)
    }

    public func transcribe(
        audioBuffers: AsyncThrowingStream<AVAudioPCMBuffer, Error>
    ) async throws -> AsyncThrowingStream<TranscriptionResult, Error> {
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )

        self.transcriber = transcriber
        self.analyzer = SpeechAnalyzer(modules: [transcriber])

        try await ensureModel(for: transcriber, locale: locale)

        guard let analyzer else {
            throw TranscriptionError.failedToSetupRecognitionStream
        }

        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        ) else {
            throw TranscriptionError.failedToSetupRecognitionStream
        }

        let (inputStream, inputContinuation) = AsyncStream.makeStream(
            of: AnalyzerInput.self
        )

        let (resultStream, resultContinuation) = AsyncThrowingStream.makeStream(
            of: TranscriptionResult.self
        )

        Task {
            do {
                try await analyzer.start(inputSequence: inputStream)
            } catch {
                resultContinuation.finish(throwing: error)
            }
        }

        Task {
            do {
                for try await buffer in audioBuffers {
                    let convertedBuffer = try converter.convertBuffer(buffer, to: analyzerFormat)
                    inputContinuation.yield(AnalyzerInput(buffer: convertedBuffer))
                }

                inputContinuation.finish()
                try await analyzer.finalizeAndFinishThroughEndOfInput()
            } catch {
                resultContinuation.finish(throwing: error)
            }
        }

        Task {
            do {
                for try await result in transcriber.results {
                    let kind: TranscriptionResult.Kind = result.isFinal ? .final : .volatile

                    resultContinuation.yield(
                        TranscriptionResult(
                            text: result.text,
                            kind: kind,
                            startTime: result.range.start.seconds
                        )
                    )
                }

                resultContinuation.finish()
            } catch {
                resultContinuation.finish(throwing: error)
            }
        }

        resultContinuation.onTermination = { _ in
            inputContinuation.finish()
        }

        return resultStream
    }

    private func audioBuffers(
        from url: URL,
        frameCapacity: AVAudioFrameCount = 4_096
    ) throws -> AsyncThrowingStream<AVAudioPCMBuffer, Error> {
        let audioFile = try AVAudioFile(forReading: url)

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    while !Task.isCancelled {
                        let framesRemaining = audioFile.length - audioFile.framePosition

                        guard framesRemaining > 0 else {
                            break
                        }

                        let nextFrameCapacity = min(frameCapacity, AVAudioFrameCount(framesRemaining))
                        guard let buffer = AVAudioPCMBuffer(
                            pcmFormat: audioFile.processingFormat,
                            frameCapacity: nextFrameCapacity
                        ) else {
                            break
                        }

                        try audioFile.read(into: buffer)

                        guard buffer.frameLength > 0 else {
                            break
                        }

                        continuation.yield(buffer)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func ensureModel(
        for transcriber: SpeechTranscriber,
        locale: Locale
    ) async throws {
        let supportedLocales = await SpeechTranscriber.supportedLocales
        let isSupported =
            supportedLocales
            .map { $0.identifier(.bcp47) }
            .contains(locale.identifier(.bcp47))

        guard isSupported else {
            throw TranscriptionError.localeNotSupported
        }

        let installedLocales = await Set(SpeechTranscriber.installedLocales)
        let isInstalled =
            installedLocales
            .map { $0.identifier(.bcp47) }
            .contains(locale.identifier(.bcp47))

        guard !isInstalled else {
            return
        }

        if let downloader = try await AssetInventory.assetInstallationRequest(
            supporting: [transcriber]
        ) {
            try await downloader.downloadAndInstall()
        }
    }
}
