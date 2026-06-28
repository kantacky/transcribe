@_exported import SwiftUI

public struct TranscribeApp: App {
    public init() {
    }

    public var body: some Scene {
        WindowGroup {
            TranscriptionView()
        }
        .defaultSize(width: 800, height: 600)
    }
}
