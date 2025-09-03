import SwiftUI
import Combine

extension Color {
    /// Initializes a color using a design token path from the "Colors" category.
    static func token(_ tokenPath: String, for colorScheme: ColorScheme) -> Color {
        let schemeVariant = (colorScheme == .dark) ? "dark" : "light"
        let fullTokenPath = "\(tokenPath).\(schemeVariant)"
        
        let tokenManager = DesignTokenManager.shared
        
        if let hexString = tokenManager.getColorValue(at: fullTokenPath) as? String {
            return Color(hex: hexString)
        } else {
            // Log a warning and return a fallback color if the token is not found.
            print("⚠️ Color token not found: \(fullTokenPath)")
            return .pink // A bright, noticeable color for debugging.
        }
    }
}

extension Font {
    /// Initializes a font using a design token path from the "Typography" category.
    static func token(_ tokenPath: String) -> Font {
        let tokenManager = DesignTokenManager.shared
        
        if let fontDict = tokenManager.getFontValue(at: tokenPath) as? [String: Any],
           let size = fontDict["size"] as? CGFloat,
           let weightString = fontDict["weight"] as? String {
            
            let weight = fontWeight(from: weightString)
            return .system(size: size, weight: weight)
            
        } else {
            // Log a warning and return a fallback font.
            print("⚠️ Font token not found: \(tokenPath)")
            return .body // Default system font as a fallback.
        }
    }

    /// Converts a string weight (e.g., "bold") to a `Font.Weight`.
    private static func fontWeight(from string: String) -> Font.Weight {
        switch string.lowercased() {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "regular": return .regular
        case "light": return .light
        case "thin": return .thin
        case "ultralight": return .ultraLight
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
}

// MARK: - View Helpers
extension View {
    /// Applies a foreground color using a design token.
    func foregroundColor(token: String) -> some View {
        self.modifier(TokenForegroundColor(tokenPath: token))
    }
}

struct TokenForegroundColor: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var tokenPath: String

    func body(content: Content) -> some View {
        content.foregroundColor(Color.token(tokenPath, for: colorScheme))
    }
}