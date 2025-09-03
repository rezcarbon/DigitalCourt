import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

class ThemeManager: ObservableObject {
    // Manually declare the objectWillChange publisher from the Combine framework.
    let objectWillChange = PassthroughSubject<Void, Never>()

    @AppStorage("appTheme") var theme: AppTheme = .dark {
        willSet {
            // Manually broadcast that our object is about to change.
            // This is the key part that fixes the conformance issue reliably.
            objectWillChange.send()
        }
        didSet {
            applyTheme()
        }
    }
    
    func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows.forEach { window in
            switch theme {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}