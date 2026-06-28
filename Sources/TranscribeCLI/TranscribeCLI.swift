import ArgumentParser
import Foundation
import TranscribeCore
import TranscribeDomain

@main
struct TranscribeCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "transcribe",
        abstract: "指定した音声ファイルをリアルタイムに文字起こしして標準出力に出力します。"
    )

    @Argument(help: "文字起こしする音声ファイルのパス")
    var audioFilePath: String

    @Option(name: [.short, .customLong("locale")], help: "文字起こしに使用するロケール (BCP-47)。例: ja-JP, en-US")
    var localeIdentifier: String?

    mutating func run() async throws {
        let url = URL(fileURLWithPath: (audioFilePath as NSString).expandingTildeInPath)

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError("ファイルが見つかりません: \(url.path)")
        }

        let locale = localeIdentifier.map { Locale(identifier: $0) } ?? .current
        let transcriber = Transcriber(locale: locale)
        let stream = try await transcriber.transcribe(audioFileURL: url)

        let isTTY = isatty(fileno(stdout)) != 0
        var lastVolatileWidth = 0

        for try await result in stream {
            let text = String(result.text.characters)
            let line = "[\(Self.formatTimestamp(result.startTime))] \(text)"

            switch result.kind {
            case .volatile:
                if isTTY {
                    let pad = max(0, lastVolatileWidth - line.count)
                    print("\r\(line)\(String(repeating: " ", count: pad))", terminator: "")
                    fflush(stdout)
                    lastVolatileWidth = line.count
                }
            case .final:
                if isTTY {
                    let pad = max(0, lastVolatileWidth - line.count)
                    print("\r\(line)\(String(repeating: " ", count: pad))")
                } else {
                    print(line)
                }
                lastVolatileWidth = 0
            }
        }

        if isTTY && lastVolatileWidth > 0 {
            print("")
        }
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
