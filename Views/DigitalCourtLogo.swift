import SwiftUI

/// Universal Digital Court Logo Component
/// Uses your actual Sith Empire logo image with customizable effects and animations
struct DigitalCourtLogo: View {
    let size: CGFloat
    let style: LogoStyle
    let animated: Bool
    
    @State private var rotation: Double = 0
    @State private var glowIntensity: Double = 0.6
    @State private var pulseScale: CGFloat = 1.0
    @State private var particleOpacity: Double = 0
    
    init(size: CGFloat = 100, style: LogoStyle = .standard, animated: Bool = false) {
        self.size = size
        self.style = style
        self.animated = animated
    }
    
    var body: some View {
        ZStack {
            // Base logo
            logoImage
            
            // Style-specific effects
            switch style {
            case .standard:
                EmptyView()
                
            case .glowing:
                glowEffects
                
            case .heroic:
                heroicEffects
                
            case .launch:
                launchEffects
            }
        }
        .onAppear {
            if animated {
                startAnimations()
            }
        }
    }
    
    private var logoImage: some View {
        Image("SithEmpireLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .scaleEffect(animated ? pulseScale : 1.0)
            .rotationEffect(.degrees(animated && style != .launch ? rotation : 0))
    }
    
    @ViewBuilder
    private var glowEffects: some View {
        // Soft glow
        Image("SithEmpireLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 1.1, height: size * 1.1)
            .opacity(0.4)
            .blur(radius: 6)
            .shadow(color: .red.opacity(0.6), radius: 8)
    }
    
    @ViewBuilder
    private var heroicEffects: some View {
        // Multiple glow layers
        Image("SithEmpireLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 1.15, height: size * 1.15)
            .opacity(glowIntensity * 0.3)
            .blur(radius: 10)
        
        Image("SithEmpireLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size * 1.3, height: size * 1.3)
            .opacity(glowIntensity * 0.1)
            .blur(radius: 20)
        
        // Rotating energy ring
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.red.opacity(0.8), .red.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: size * 1.4, height: size * 1.4)
            .rotationEffect(.degrees(rotation))
            .opacity(glowIntensity * 0.6)
    }
    
    @ViewBuilder
    private var launchEffects: some View {
        // For launch screen: NO background effects, completely clean logo
        EmptyView()
    }
    
    private func startAnimations() {
        // Skip ALL animations for launch style to make it completely static
        if style == .launch {
            // Set static values for launch style
            glowIntensity = 0.4
            pulseScale = 1.0
            return
        }
        
        // Rotation animation (skip for launch style)
        withAnimation(.linear(duration: animated ? 60 : 120).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Glow pulsing (skip for launch style)
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowIntensity = 0.4
        }
        
        // Scale pulsing (skip for launch style)
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

enum LogoStyle {
    case standard       // Plain logo, no effects
    case glowing       // Subtle glow effect
    case heroic        // Enhanced glow with energy ring
    case launch        // Full launch screen effects
}

// MARK: - Convenience Extensions

extension DigitalCourtLogo {
    // Quick access methods for common uses
    static func appIcon(size: CGFloat = 60) -> some View {
        DigitalCourtLogo(size: size, style: .standard, animated: false)
    }
    
    static func navigation(size: CGFloat = 30) -> some View {
        DigitalCourtLogo(size: size, style: .glowing, animated: false)
    }
    
    static func login(size: CGFloat = 120) -> some View {
        DigitalCourtLogo(size: size, style: .heroic, animated: true)
    }
    
    static func launch(size: CGFloat = 220) -> some View {
        DigitalCourtLogo(size: size, style: .launch, animated: true)
    }
}

// MARK: - Preview
struct DigitalCourtLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Different styles
            DigitalCourtLogo(size: 100, style: .standard, animated: false)
            DigitalCourtLogo(size: 100, style: .glowing, animated: false)
            DigitalCourtLogo(size: 100, style: .heroic, animated: true)
            DigitalCourtLogo(size: 200, style: .launch, animated: true)
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}