import SwiftUI
import Combine

/// A view modifier that applies a glass morphism effect
struct GlassMorphism: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color
    var blurRadius: CGFloat
    var opacity: Double
    var borderColor: Color
    var borderWidth: CGFloat
    
    init(
        backgroundColor: Color = Color.clear,
        blurRadius: CGFloat = 20,
        opacity: Double = 0.3,
        borderColor: Color = Color.white,
        borderWidth: CGFloat = 0.5
    ) {
        self.backgroundColor = backgroundColor
        self.blurRadius = blurRadius
        self.opacity = opacity
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                backgroundColor
                    .opacity(opacity)
                    .blur(radius: blurRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor.opacity(0.3), lineWidth: borderWidth)
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

/// A view modifier for glass morphism cards
struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .modifier(GlassMorphism(
                backgroundColor: Color.token("Fills.2 Secondary", for: colorScheme),
                blurRadius: 15,
                opacity: 0.25,
                borderColor: Color.white,
                borderWidth: 0.8
            ))
    }
}

/// A view modifier for glass morphism buttons
struct GlassButton: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var accentColor: Color
    
    init(accentColor: Color = Color.token("Accent Colors.8 Blue", for: .dark)) {
        self.accentColor = accentColor
    }
    
    func body(content: Content) -> some View {
        content
            .padding()
            .modifier(GlassMorphism(
                backgroundColor: accentColor,
                blurRadius: 10,
                opacity: 0.2,
                borderColor: accentColor,
                borderWidth: 1
            ))
    }
}

extension View {
    /// Applies a glass morphism effect to the view
    func glassMorphism(
        backgroundColor: Color = Color.clear,
        blurRadius: CGFloat = 20,
        opacity: Double = 0.3,
        borderColor: Color = Color.white,
        borderWidth: CGFloat = 0.5
    ) -> some View {
        self.modifier(GlassMorphism(
            backgroundColor: backgroundColor,
            blurRadius: blurRadius,
            opacity: opacity,
            borderColor: borderColor,
            borderWidth: borderWidth
        ))
    }
    
    /// Applies a glass card styling to the view
    func glassCard() -> some View {
        self.modifier(GlassCard())
    }
    
    /// Applies a glass button styling to the view
    func glassButton(accentColor: Color = Color.token("Accent Colors.8 Blue", for: .dark)) -> some View {
        self.modifier(GlassButton(accentColor: accentColor))
    }
}