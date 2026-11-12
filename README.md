# Transcribe

[![CI](https://github.com/kantacky/transcribe/actions/workflows/ci.yml/badge.svg)](https://github.com/kantacky/transcribe/actions/workflows/ci.yml)

## Install CLI

```zsh
brew install kantacky/tap/transcribe
```

## Speaker diarization

`--diarize` (`-d`) で話者分離を行い、発言ごとに話者を付けて出力します。
話者分離には [FluidAudio](https://github.com/FluidInference/FluidAudio) のオフラインパイプラインを使い、初回はモデルをダウンロードします。
話者分離は録音全体を見て行うため、確定した文字起こしは最後にまとめて出力されます。

```zsh
transcribe meeting.m4a --diarize --locale ja-JP
transcribe meeting.m4a --diarize --min-speakers 2 --max-speakers 3
```

```text
[0:00] Speaker 1: こんにちは。
[0:03] Speaker 2: よろしくお願いします。
```

アプリではツールバーの「話者を分離」をオンにしてから音声ファイルをドロップします。

&copy; 2026 Kanta Oikawa
