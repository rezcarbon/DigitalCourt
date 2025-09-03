import SwiftUI

/// Specialized version of the Real Sith Empire logo for login screen with subtle animations
struct LoginSithLogo: View {
    let size: CGFloat
    
    var body: some View {
        RealSithEmpireLogo(size: size, glowEffect: true, animated: true)
    }
}

struct LoginSithLogo_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            LoginSithLogo(size: 120)
        }
        .preferredColorScheme(.dark)
    }
}