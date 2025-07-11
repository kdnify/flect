import SwiftUI

struct LaunchScreen: View {
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.backgroundHex
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("flect")
                    .font(.system(size: 48, weight: .light, design: .default))
                    .foregroundColor(.textMainHex)
                    .opacity(opacity)
                    .scaleEffect(scale)
                
                // Subtle loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.accentHex.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .scaleEffect(opacity > 0.5 ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: opacity
                            )
                    }
                }
                .opacity(opacity * 0.8)
            }
        }
        .onAppear {
            // Fade in animation
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            
            // Hold for a moment, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeIn(duration: 0.6)) {
                    opacity = 0.0
                    scale = 1.1
                }
                
                // Complete after fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    LaunchScreen {
        print("Launch completed")
    }
} 