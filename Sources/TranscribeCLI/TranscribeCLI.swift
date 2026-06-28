import ArgumentParser
import Darwin
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
        var lastVolatileRows = 0

        for try await result in stream {
            let text = String(result.text.characters)
            let line = "[\(Self.formatTimestamp(result.startTime))] \(text)"

            switch result.kind {
            case .volatile:
                if isTTY {
                    Self.clearVolatile(rows: lastVolatileRows)
                    print(line, terminator: "")
                    fflush(stdout)
                    lastVolatileRows = Self.rowsOccupied(by: line)
                }
            case .final:
                if isTTY {
                    Self.clearVolatile(rows: lastVolatileRows)
                    print(line)
                } else {
                    print(line)
                }
                lastVolatileRows = 0
            }
        }

        if isTTY && lastVolatileRows > 0 {
            print("")
        }
    }

    private static func terminalColumns() -> Int {
        var ws = winsize()
        if ioctl(fileno(stdout), TIOCGWINSZ, &ws) == 0, ws.ws_col > 0 {
            return Int(ws.ws_col)
        }
        return 80
    }

    private static func displayWidth(of string: String) -> Int {
        var width = 0
        for scalar in string.unicodeScalars {
            let value = scalar.value
            if value == 0 { continue }
            // East Asian Wide / Fullwidth ranges (approximation)
            if (0x1100...0x115F).contains(value)
                || (0x2E80...0x303E).contains(value)
                || (0x3041...0x33FF).contains(value)
                || (0x3400...0x4DBF).contains(value)
                || (0x4E00...0x9FFF).contains(value)
                || (0xA000...0xA4CF).contains(value)
                || (0xAC00...0xD7A3).contains(value)
                || (0xF900...0xFAFF).contains(value)
                || (0xFE30...0xFE4F).contains(value)
                || (0xFF00...0xFF60).contains(value)
                || (0xFFE0...0xFFE6).contains(value)
                || (0x20000...0x2FFFD).contains(value)
                || (0x30000...0x3FFFD).contains(value)
            {
                width += 2
            } else {
                width += 1
            }
        }
        return width
    }

    private static func rowsOccupied(by line: String) -> Int {
        let cols = terminalColumns()
        let width = displayWidth(of: line)
        if width == 0 { return 1 }
        return (width + cols - 1) / cols
    }

    private static func clearVolatile(rows: Int) {
        guard rows > 0 else { return }
        // Move cursor to start of current line
        print("\r", terminator: "")
        // Move up to the first row of the previous render
        if rows > 1 {
            print("\u{1B}[\(rows - 1)A", terminator: "")
        }
        // Erase from cursor to end of screen
        print("\u{1B}[0J", terminator: "")
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
