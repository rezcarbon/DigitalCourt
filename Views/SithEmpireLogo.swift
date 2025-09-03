import SwiftUI

struct SithEmpireLogo: View {
    let size: CGFloat
    let glowEffect: Bool
    
    init(size: CGFloat = 100, glowEffect: Bool = true) {
        self.size = size
        self.glowEffect = glowEffect
    }
    
    var body: some View {
        ZStack {
            // Background circle with crown spikes
            BackgroundWithSpikes(size: size)
            
            // Main hexagonal frame
            HexagonalFrame(size: size * 0.7)
            
            // Dragon/Serpent in the center
            DragonSymbol(size: size * 0.4)
        }
        .frame(width: size, height: size)
        .if(glowEffect) { view in
            view.shadow(color: .red.opacity(0.6), radius: size * 0.1)
        }
    }
}

struct BackgroundWithSpikes: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Dark background circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.7),
                            Color.black
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size * 0.9, height: size * 0.9)
            
            // Crown spikes around the edge
            ForEach(0..<12, id: \.self) { index in
                SpikeShape()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: size * 0.08, height: size * 0.25)
                    .offset(y: -size * 0.45)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
    }
}

struct HexagonalFrame: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Outer hexagon
            HexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.red,
                            Color.red.opacity(0.8),
                            Color.red.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.06
                )
                .frame(width: size, height: size)
            
            // Inner hexagon details
            HexagonShape()
                .stroke(
                    Color.red.opacity(0.4),
                    lineWidth: size * 0.02
                )
                .frame(width: size * 0.85, height: size * 0.85)
            
            // Corner reinforcements
            ForEach(0..<6, id: \.self) { index in
                CornerReinforcement()
                    .fill(Color.red)
                    .frame(width: size * 0.12, height: size * 0.08)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
        }
    }
}

struct DragonSymbol: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Dragon head and body
            DragonPath()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red,
                            Color.red.opacity(0.9),
                            Color.red.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Dragon eyes (glowing effect)
            Circle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(x: -size * 0.1, y: -size * 0.15)
                .shadow(color: .yellow, radius: 3)
            
            Circle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(x: size * 0.05, y: -size * 0.15)
                .shadow(color: .yellow, radius: 3)
        }
    }
}

// MARK: - Custom Shapes

struct SpikeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        
        for i in 0..<6 {
            let angle = Double(i) * .pi / 3.0
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        
        return path
    }
}

struct CornerReinforcement: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Create a small hexagonal reinforcement
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.25))
        path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.5, y: height))
        path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.75))
        path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.25))
        path.closeSubpath()
        
        return path
    }
}

struct DragonPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Dragon head (simplified)
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.2))
        
        // Top of head
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.3),
            control1: CGPoint(x: width * 0.4, y: height * 0.1),
            control2: CGPoint(x: width * 0.6, y: height * 0.15)
        )
        
        // Dragon snout/mouth
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.5),
            control1: CGPoint(x: width * 0.75, y: height * 0.35),
            control2: CGPoint(x: width * 0.8, y: height * 0.4)
        )
        
        // Lower jaw
        path.addCurve(
            to: CGPoint(x: width * 0.6, y: height * 0.6),
            control1: CGPoint(x: width * 0.75, y: height * 0.55),
            control2: CGPoint(x: width * 0.7, y: height * 0.58)
        )
        
        // Neck curve
        path.addCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.8),
            control1: CGPoint(x: width * 0.5, y: height * 0.65),
            control2: CGPoint(x: width * 0.45, y: height * 0.7)
        )
        
        // Body curve (S-shape)
        path.addCurve(
            to: CGPoint(x: width * 0.6, y: height * 0.9),
            control1: CGPoint(x: width * 0.35, y: height * 0.85),
            control2: CGPoint(x: width * 0.5, y: height * 0.88)
        )
        
        // Tail
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.7),
            control1: CGPoint(x: width * 0.4, y: height * 0.9),
            control2: CGPoint(x: width * 0.25, y: height * 0.8)
        )
        
        // Back to head
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.2),
            control1: CGPoint(x: width * 0.15, y: height * 0.6),
            control2: CGPoint(x: width * 0.2, y: height * 0.3)
        )
        
        path.closeSubpath()
        
        return path
    }
}

// MARK: - View Extension for Conditional Modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

struct SithEmpireLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Large version
            SithEmpireLogo(size: 200, glowEffect: true)
            
            // Medium version
            SithEmpireLogo(size: 100, glowEffect: true)
            
            // Small version
            SithEmpireLogo(size: 50, glowEffect: false)
            
            // In different colors (customizable)
            SithEmpireLogo(size: 100, glowEffect: true)
                .colorScheme(.dark)
        }
        .padding()
        .background(Color.black)
    }
}