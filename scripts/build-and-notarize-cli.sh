#!/usr/bin/env bash
#
# TranscribeCLI をビルド・署名・公証して、Homebrew tap で配布できる
# tar.gz を dist/ に作成する。
#
# 事前準備:
#   1. Developer ID Application 証明書を Keychain に入れておく
#        security find-identity -v -p codesigning
#      で identity 文字列を確認し、環境変数 SIGN_IDENTITY に渡す。
#   2. notarytool の認証情報を Keychain プロファイルに保存しておく
#        xcrun notarytool store-credentials "$KEYCHAIN_PROFILE" \
#          --key "$ASC_API_KEY_PATH" \
#          --key-id "$ASC_API_KEY_ID" \
#          --issuer "$ASC_API_KEY_ISSUER_ID"
#
# 使い方:
#   VERSION=0.1.0 \
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   KEYCHAIN_PROFILE=notarytool-profile \
#     ./scripts/build-and-notarize-cli.sh

set -euo pipefail

: "${VERSION:?VERSION is required (e.g. 0.1.0)}"
: "${SIGN_IDENTITY:?SIGN_IDENTITY is required}"
: "${KEYCHAIN_PROFILE:?KEYCHAIN_PROFILE is required}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DIST="$REPO_ROOT/dist"
mkdir -p "$DIST"

# 1. リリースビルド
swift build \
  --configuration release \
  --product TranscribeCLI \
  --disable-sandbox

BIN="$REPO_ROOT/.build/release/TranscribeCLI"

# 2. ハードンドランタイム + タイムスタンプ付きで署名
codesign --force \
  --sign "$SIGN_IDENTITY" \
  --options runtime \
  --timestamp \
  "$BIN"

codesign --verify --strict --verbose=2 "$BIN"

# 3. 公証申請用に zip 化（notarytool は zip/pkg/dmg を受け付ける）
NOTARIZE_ZIP="$DIST/TranscribeCLI-notarize.zip"
rm -f "$NOTARIZE_ZIP"
ditto -c -k --keepParent "$BIN" "$NOTARIZE_ZIP"

# 4. 公証申請（完了まで待機）
xcrun notarytool submit "$NOTARIZE_ZIP" \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --wait

# 単体 Mach-O には stapler を当てられないため staple は省略。
# Homebrew 経由でインストールされる場合は quarantine が付かないため、
# 公証チェックはオンライン照会のみで通る。

# 5. 配布用 tarball を作成
ARCH="$(uname -m)"
TARBALL="$DIST/transcribe-${VERSION}-${ARCH}.tar.gz"
rm -f "$TARBALL"
tar -C "$REPO_ROOT/.build/release" -czf "$TARBALL" TranscribeCLI

SHA256="$(shasum -a 256 "$TARBALL" | awk '{print $1}')"

echo
echo "Built: $TARBALL"
echo "SHA256: $SHA256"
echo
echo "次の手順:"
echo "  gh release upload v${VERSION} \"$TARBALL\""
echo "  homebrew-tap の Formula/transcribe.rb の url / sha256 を更新"
