import SwiftUI
import Combine

struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color.token("Fills.1 Primary", for: colorScheme).ignoresSafeArea()
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.token("Accent Colors.8 Blue", for: colorScheme).opacity(0.3),
                    Color.token("Fills.1 Primary", for: colorScheme).opacity(0.1),
                    Color.token("Accent Colors.4 Orange", for: colorScheme).opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Adding a subtle radial gradient for the "liquid" feel
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.05),
                    Color.clear
                ]),
                center: .bottom,
                startRadius: 200,
                endRadius: 700
            )
            .ignoresSafeArea()
        }
    }
}