#if os(macOS)
import AppKit
import Foundation

enum CLIInstaller {
    static let bundledBinaryName = "TranscribeCLI"
    static let installedBinaryName = "transcribe"

    enum InstallError: LocalizedError {
        case binaryNotBundled
        case destinationNotWritable(URL)

        var errorDescription: String? {
            switch self {
            case .binaryNotBundled:
                String(
                    localized: "The CLI binary is not bundled with this app.",
                    bundle: .module
                )
            case .destinationNotWritable(let url):
                String(
                    localized: "Cannot write to \(url.path).",
                    bundle: .module
                )
            }
        }
    }

    static var bundledBinaryURL: URL? {
        Bundle.main.url(forResource: bundledBinaryName, withExtension: nil)
    }

    static var defaultDestinationDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".local", directoryHint: .isDirectory)
            .appending(path: "bin", directoryHint: .isDirectory)
    }

    @MainActor
    static func promptAndInstall() async throws -> URL {
        guard let source = bundledBinaryURL else {
            throw InstallError.binaryNotBundled
        }

        let panel = NSOpenPanel()
        panel.title = String(localized: "Install CLI Tool", bundle: .module)
        panel.message = String(
            localized: "Select the directory to install \"transcribe\" into. ~/.local/bin is recommended.",
            bundle: .module
        )
        panel.prompt = String(localized: "Install", bundle: .module)
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = defaultDestinationDirectory

        guard panel.runModal() == .OK, let destinationDirectory = panel.url else {
            throw CancellationError()
        }

        let didStartAccess = destinationDirectory.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                destinationDirectory.stopAccessingSecurityScopedResource()
            }
        }

        return try install(from: source, into: destinationDirectory)
    }

    static func install(from source: URL, into directory: URL) throws -> URL {
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw InstallError.destinationNotWritable(directory)
        }

        let destination = directory.appending(path: installedBinaryName, directoryHint: .notDirectory)

        if fileManager.fileExists(atPath: destination.path)
            || (try? destination.checkResourceIsReachable()) == true
        {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.createSymbolicLink(at: destination, withDestinationURL: source)

        return destination
    }
}
#endif
