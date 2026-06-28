# AGENTS

## ツール利用ルール

- Xcode 関連の操作（ビルド・テスト実行・ファイル編集・ログ取得・プレビュー描画など）は、`xcodebuild` などのシェルコマンドを直接実行せず、**Xcode MCP**（`mcp__xcode__*` ツール群）を使用すること。
  - 例: ビルドは `mcp__xcode__BuildProject`、テストは `mcp__xcode__RunAllTests` / `mcp__xcode__RunSomeTests`、ファイル読み書きは `mcp__xcode__XcodeRead` / `mcp__xcode__XcodeWrite` を用いる。
  - Xcode MCP で実現できない操作に限り、シェルコマンドの利用を検討する。
