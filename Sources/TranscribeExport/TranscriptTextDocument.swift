import SwiftUI
import UniformTypeIdentifiers

public struct TranscriptTextDocument: FileDocument {
    public static var readableContentTypes: [UTType] {
        [.plainText]
    }

    public var text: String

    public init(text: String = "") {
        self.text = text
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            text = ""
            return
        }

        text = String(decoding: data, as: UTF8.self)
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
