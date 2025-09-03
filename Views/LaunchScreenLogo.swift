import SwiftUI

struct LaunchScreenLogo: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 50
    @State private var showParticles = false
    @State private var particleOpacity: Double = 0
    @State private var phase: LaunchAnimationPhase = .initial
    
    var body: some View {
        ZStack {
            // Pure black background only
            Color.black
                .ignoresSafeArea()
            
            // Particle system
            if showParticles {
                ParticleSystemView()
                    .opacity(particleOpacity)
            }
            
            VStack(spacing: 60) {
                // Completely static logo - reduced by 50% and no rotation
                ZStack {
                    Image("SithEmpireLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 220, height: 220)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                // Animated app title
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
            }
            
            // Power-up flash effect
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            .red.opacity(phase == .powerUp ? 0.4 : 0),
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
            startLaunchSequence()
        }
    }
    
    private func startLaunchSequence() {
        // Phase 1: Logo appears (0-1s)
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 0.9
            logoOpacity = 1.0
            phase = .appearing
        }
        
        // Phase 2: Power up effect (1-1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                logoScale = 1.1
                phase = .powerUp
            }
            
            // Show particles
            showParticles = true
            withAnimation(.easeIn(duration: 0.3)) {
                particleOpacity = 1.0
            }
        }
        
        // Phase 3: Settle and show text (1.5-2.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                phase = .stable
            }
            
            withAnimation(.easeOut(duration: 0.8)) {
                textOpacity = 1.0
                textOffset = 0
            }
        }
    }
}

enum LaunchAnimationPhase {
    case initial
    case appearing
    case powerUp
    case stable
}

struct ParticleSystemView: View {
    @State private var particles: [LaunchParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(.red.opacity(0.6))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { index in
            LaunchParticle(
                id: index,
                position: CGPoint(
                    x: Double.random(in: 50...350),
                    y: Double.random(in: 200...600)
                ),
                size: Double.random(in: 2...6),
                opacity: Double.random(in: 0.3...0.8)
            )
        }
    }
}

struct LaunchParticle {
    let id: Int
    let position: CGPoint
    let size: Double
    let opacity: Double
}

struct LaunchScreenLogo_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenLogo()
            .preferredColorScheme(.dark)
    }
}