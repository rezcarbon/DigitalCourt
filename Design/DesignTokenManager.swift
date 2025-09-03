import SwiftUI

class DesignTokenManager {
    static let shared = DesignTokenManager()
    
    private var colorTokens: [String: Any] = [:]
    private var typographyTokens: [String: Any] = [:]
    
    private init() {
        loadTokens()
    }
    
    private func loadTokens() {
        guard let url = Bundle.main.url(forResource: "apple-ios-ui-kit.tokens", withExtension: "json") else {
            fatalError("Design tokens file not found in bundle.")
        }
        
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                self.colorTokens = json["Colors"] as? [String: Any] ?? [:]
                self.typographyTokens = json["Typography"] as? [String: Any] ?? [:]
            }
        } catch {
            fatalError("Failed to parse design tokens: \(error)")
        }
    }
    
    /// Helper to traverse a specific token dictionary with a dot-separated path.
    private func value(from tokens: [String: Any], at path: String) -> Any? {
        let keys = path.split(separator: ".")
        var current: Any? = tokens
        
        for key in keys {
            if let dict = current as? [String: Any], let nextValue = dict[String(key)] {
                current = nextValue
            } else {
                return nil
            }
        }
        return current
    }

    /// Public getter specifically for color token values.
    func getColorValue(at path: String) -> Any? {
        return value(from: colorTokens, at: path)
    }

    /// Public getter specifically for font token values.
    func getFontValue(at path: String) -> Any? {
        return value(from: typographyTokens, at: path)
    }
}

// MARK: - Helpers
extension Font.Weight {
    init(from: Int) {
        switch from {
        case 100: self = .thin
        case 200: self = .ultraLight
        case 300: self = .light
        case 400: self = .regular
        case 500: self = .medium
        case 600: self = .semibold
        case 700: self = .bold
        case 800: self = .heavy
        case 900: self = .black
        default: self = .regular
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}