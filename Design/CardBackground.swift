import SwiftUI
import Combine

/// A view modifier that applies a standard card-like background and styling.
struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.token("Fills.2 Secondary", for: colorScheme))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.token("Fills.3 Tertiary", for: colorScheme), lineWidth: 1)
            )
    }
}

extension View {
    /// Applies a standard card-like background and styling to the view.
    func cardBackground() -> some View {
        self.modifier(CardBackground())
    }
}