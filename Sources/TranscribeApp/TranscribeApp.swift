@_exported import SwiftUI

public struct TranscribeApp: App {
    public init() {
    }

    public var body: some Scene {
        WindowGroup {
            TranscriptionView()
        }
        .defaultSize(width: 800, height: 600)
        #if os(macOS)
        .commands {
            CommandGroup(after: .appInfo) {
                InstallCLICommand()
            }
        }
        #endif
    }
}

#if os(macOS)
private struct InstallCLICommand: View {
    @State private var isShowingResult = false
    @State private var resultMessage = ""
    @State private var resultIsError = false

    var body: some View {
        Button {
            Task { await install() }
        } label: {
            Text("Install CLI Tool…", bundle: .module)
        }
        .disabled(CLIInstaller.bundledBinaryURL == nil)
        .alert(
            resultIsError
                ? Text("Installation failed", bundle: .module)
                : Text("CLI installed", bundle: .module),
            isPresented: $isShowingResult
        ) {
            Button {
                isShowingResult = false
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text(resultMessage)
        }
    }

    @MainActor
    private func install() async {
        do {
            let destination = try await CLIInstaller.promptAndInstall()
            resultIsError = false
            resultMessage = String(
                localized: "Installed to \(destination.path).",
                bundle: .module
            )
            isShowingResult = true
        } catch is CancellationError {
            return
        } catch {
            resultIsError = true
            resultMessage = error.localizedDescription
            isShowingResult = true
        }
    }
}
#endif
