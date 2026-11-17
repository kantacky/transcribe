import CoreML
@preconcurrency import FluidAudio
import Foundation
import TranscribeDomain

/// FluidAudio のオフラインパイプライン (pyannote 系) で話者分離する。
/// 初回はモデルをダウンロードする。
public final actor SpeakerDiarizer {
    private let minSpeakers: Int?
    private let maxSpeakers: Int?

    /// - Parameters:
    ///   - minSpeakers: 推定する話者数の下限 (`nil` なら自動推定)。
    ///   - maxSpeakers: 推定する話者数の上限 (`nil` なら自動推定)。
    public init(minSpeakers: Int? = nil, maxSpeakers: Int? = nil) {
        self.minSpeakers = minSpeakers
        self.maxSpeakers = maxSpeakers
    }

    public func diarize(audioFileURL: URL) async throws -> [SpeakerSegment] {
        // FluidAudio の debug ログがライブ表示に混ざらないようにする。
        AppLogger.minimumLevel = .warning
        var config = OfflineDiarizerConfig.default
        config.clustering.minSpeakers = minSpeakers
        config.clustering.maxSpeakers = maxSpeakers

        let manager = OfflineDiarizerManager(config: config)
        let modelConfiguration = MLModelConfiguration()
        modelConfiguration.computeUnits = .cpuAndNeuralEngine
        // prewarm でも `[Profiling]` 行が stderr に直接書かれる。
        try await Self.withStandardErrorSilenced {
            try await manager.prepareModels(configuration: modelConfiguration)
        }

        let samples = try AudioConverter().resampleAudioFile(audioFileURL)

        let result: DiarizationResult
        do {
            // `[Profiling]` 行は AppLogger を経由せず stderr に直接書かれるため、処理中だけ stderr を捨てる。
            result = try await Self.withStandardErrorSilenced {
                try await manager.process(audio: samples)
            }
        } catch OfflineDiarizationError.noSpeechDetected {
            return []
        }

        return Self.normalize(
            result.segments.map {
                (
                    id: $0.speakerId,
                    start: TimeInterval($0.startTimeSeconds),
                    end: TimeInterval($0.endTimeSeconds)
                )
            }
        )
    }

    private static func withStandardErrorSilenced<T>(
        _ body: () async throws -> T
    ) async rethrows -> T {
        let saved = dup(STDERR_FILENO)
        let devNull = open("/dev/null", O_WRONLY)
        guard saved >= 0, devNull >= 0 else {
            if saved >= 0 { close(saved) }
            if devNull >= 0 { close(devNull) }
            return try await body()
        }
        dup2(devNull, STDERR_FILENO)
        close(devNull)
        defer {
            dup2(saved, STDERR_FILENO)
            close(saved)
        }
        return try await body()
    }

    /// 話者 ID を最初に話した順の番号 (1 始まり) に振り直す。
    static func normalize(
        _ segments: [(id: String, start: TimeInterval, end: TimeInterval)]
    ) -> [SpeakerSegment] {
        let sorted = segments.sorted { $0.start < $1.start }
        var numbers: [String: Int] = [:]
        var result: [SpeakerSegment] = []
        for segment in sorted {
            let number: Int
            if let existing = numbers[segment.id] {
                number = existing
            } else {
                number = numbers.count + 1
                numbers[segment.id] = number
            }
            result.append(
                SpeakerSegment(
                    speakerNumber: number,
                    startTime: segment.start,
                    endTime: segment.end
                )
            )
        }
        return result
    }
}
