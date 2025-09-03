import SwiftUI

/// Real Sith Empire Logo using the actual image asset
/// This replaces the programmatic version with your custom logo
struct RealSithEmpireLogo: View {
    let size: CGFloat
    let glowEffect: Bool
    let animated: Bool
    
    @State private var rotation: Double = 0
    @State private var glowIntensity: Double = 0.6
    @State private var pulseScale: CGFloat = 1.0
    
    init(size: CGFloat = 100, glowEffect: Bool = true, animated: Bool = false) {
        self.size = size
        self.glowEffect = glowEffect
        self.animated = animated
    }
    
    var body: some View {
        ZStack {
            // Your actual logo image
            Image("SithEmpireLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .scaleEffect(animated ? pulseScale : 1.0)
                .rotationEffect(.degrees(animated ? rotation : 0))
            
            // Glow effect overlay if enabled
            if glowEffect {
                Image("SithEmpireLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 1.1, height: size * 1.1)
                    .opacity(glowIntensity * 0.4)
                    .blur(radius: 8)
                    .scaleEffect(animated ? pulseScale * 1.05 : 1.05)
                
                // Additional outer glow
                Image("SithEmpireLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 1.2, height: size * 1.2)
                    .opacity(glowIntensity * 0.2)
                    .blur(radius: 15)
                    .scaleEffect(animated ? pulseScale * 1.1 : 1.1)
            }
        }
        .shadow(
            color: glowEffect ? .red.opacity(glowIntensity * 0.6) : .clear,
            radius: glowEffect ? 10 : 0
        )
        .onAppear {
            if animated {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Subtle rotation (very slow)
        withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Glow pulsing
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            glowIntensity = 0.3
        }
        
        // Subtle scale pulsing
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

// MARK: - Enhanced Launch Screen Logo

struct EnhancedLaunchScreenLogo: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0.0
    @State private var logoRotation: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var glowOpacity: Double = 0
    
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 50
    
    @State private var particleOpacity: Double = 0
    @State private var showParticles = false
    
    @State private var phase: AnimationPhase = .initial
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground()
            
            // Particle system
            if showParticles {
                ParticleSystem()
                    .opacity(particleOpacity)
            }
            
            VStack(spacing: 60) {
                // Your real logo with enhanced animations
                ZStack {
                    // Main logo
                    RealSithEmpireLogo(size: 220, glowEffect: false, animated: false)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .rotationEffect(.degrees(logoRotation))
                    
                    // Glow layers using your actual logo
                    RealSithEmpireLogo(size: 220 * 1.1, glowEffect: false, animated: false)
                        .opacity(glowOpacity * 0.3)
                        .blur(radius: 8)
                        .scaleEffect(logoScale * 1.1)
                    
                    RealSithEmpireLogo(size: 220 * 1.2, glowEffect: false, animated: false)
                        .opacity(glowOpacity * 0.1)
                        .blur(radius: 15)
                        .scaleEffect(logoScale * 1.2)
                    
                    // Rotating energy rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .red.opacity(0.8),
                                        .red.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 280 + CGFloat(index * 40))
                            .rotationEffect(.degrees(logoRotation + Double(index * 120)))
                            .opacity(glowOpacity * 0.6)
                    }
                }
                .shadow(
                    color: .red.opacity(glowOpacity),
                    radius: glowRadius
                )
                
                // Animated text
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(Array("DIGITAL COURT".enumerated()), id: \.offset) { index, character in
                            Text(String(character))
                                .font(.system(size: 32, weight: .black, design: .default))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .red.opacity(0.5), radius: 3)
                                .scaleEffect(textOpacity)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.05),
                                    value: textOpacity
                                )
                        }
                    }
                    
                    Text("THE INFINITE RISES")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.red.opacity(0.7))
                        .tracking(4)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                        .shadow(color: .red.opacity(0.3), radius: 2)
                }
                .opacity(textOpacity)
            }
            
            // Power-up flash effect
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            .red.opacity(phase == .powerUp ? 0.6 : 0),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Phase 1: Initial appearance (0-1s)
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 0.9
            logoOpacity = 1.0
            glowRadius = 10
            glowOpacity = 0.6
            phase = .appearing
        }
        
        // Phase 2: Power up (1-1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                logoScale = 1.1
                glowRadius = 25
                glowOpacity = 0.9
                phase = .powerUp
            }
            
            // Show particles
            showParticles = true
            withAnimation(.easeIn(duration: 0.3)) {
                particleOpacity = 1.0
            }
        }
        
        // Phase 3: Settle and text appear (1.5-2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                glowRadius = 15
                glowOpacity = 0.7
                phase = .stable
            }
            
            withAnimation(.easeOut(duration: 0.8)) {
                textOpacity = 1.0
                textOffset = 0
            }
        }
        
        // Phase 4: Continuous animations (2.5s+)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            startContinuousAnimations()
        }
    }
    
    private func startContinuousAnimations() {
        // Rotating effects
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            logoRotation = 360
        }
        
        // Pulsing glow
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.4
            glowRadius = 20
        }
        
        // Subtle scale pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            logoScale = 1.05
        }
    }
}

// MARK: - Supporting Views and Models (reused)

struct AnimatedBackground: View {
    @State private var gradientRotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    .red.opacity(0.1),
                    .black.opacity(0.9),
                    .black
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .rotationEffect(.degrees(gradientRotation))
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                    gradientRotation = 360
                }
            }
            
            GridPattern()
                .opacity(0.1)
        }
    }
}

struct GridPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 50
            
            for x in stride(from: 0, through: size.width, by: spacing) {
                let path = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(.red.opacity(0.2)), lineWidth: 0.5)
            }
            
            for y in stride(from: 0, through: size.height, by: spacing) {
                let path = Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.red.opacity(0.2)), lineWidth: 0.5)
            }
        }
    }
}

struct ParticleSystem: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.red.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: particle.blur)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: UIScreen.main.bounds.width * 0.5 + CGFloat.random(in: -100...100),
                    y: UIScreen.main.bounds.height * 0.4 + CGFloat.random(in: -50...50)
                ),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8),
                blur: CGFloat.random(in: 0...2)
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for index in particles.indices {
                withAnimation(.easeOut(duration: 1.0)) {
                    particles[index].position.x += CGFloat.random(in: -2...2)
                    particles[index].position.y += CGFloat.random(in: -2...2)
                    particles[index].opacity *= 0.98
                }
            }
            
            particles.removeAll { $0.opacity < 0.1 }
            if particles.count < 15 {
                particles.append(
                    Particle(
                        position: CGPoint(
                            x: UIScreen.main.bounds.width * 0.5 + CGFloat.random(in: -100...100),
                            y: UIScreen.main.bounds.height * 0.4 + CGFloat.random(in: -50...50)
                        ),
                        size: CGFloat.random(in: 2...6),
                        opacity: Double.random(in: 0.3...0.8),
                        blur: CGFloat.random(in: 0...2)
                    )
                )
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

enum AnimationPhase {
    case initial
    case appearing
    case powerUp
    case stable
}

// MARK: - Preview
struct RealSithEmpireLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            RealSithEmpireLogo(size: 200, glowEffect: true, animated: true)
            RealSithEmpireLogo(size: 100, glowEffect: true, animated: false)
            RealSithEmpireLogo(size: 50, glowEffect: false, animated: false)
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}