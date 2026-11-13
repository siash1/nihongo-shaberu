import Foundation

/// Where the app's Convex backend lives. The deployment URL is public (it is in every request),
/// not a secret.
nonisolated enum BackendConfig {
    static let deploymentURL: URL = {
        #if DEBUG
        // For testing against a local backend (`npx convex dev`), set KANA_BACKEND_URL in the
        // scheme's environment, e.g. http://127.0.0.1:3210.
        if let override = ProcessInfo.processInfo.environment["KANA_BACKEND_URL"],
           let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://brave-vole-856.eu-west-1.convex.cloud")!
    }()
}
