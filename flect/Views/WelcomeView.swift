import SwiftUI

struct WelcomeView: View {
    @State private var showingOnboarding = false
    @Environment(\.dismiss) private var dismiss
    // Animation states
    @State private var logoPulse = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showPills = false
    @State private var buttonScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top safe area padding
                Rectangle()
                    .fill(Color.backgroundHex)
                    .frame(height: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(.all, edges: .top)
                // Main content
                VStack(spacing: 0) {
                    Spacer()
                    // Welcome content
                    VStack(spacing: 48) {
                        // Brand section
                        VStack(spacing: 24) {
                            // Animated logo
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(
                                    colors: [
                                        Color.orange.opacity(logoPulse ? 0.9 : 0.8),
                                        Color.purple.opacity(logoPulse ? 0.8 : 0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: logoPulse ? 90 : 80, height: logoPulse ? 90 : 80)
                                .shadow(color: .orange.opacity(0.3), radius: 16, x: 0, y: 8)
                                .scaleEffect(logoPulse ? 1.08 : 1.0)
                                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: logoPulse)
                                .onAppear { logoPulse = true }
                            VStack(spacing: 16) {
                                Text("flect")
                                    .font(.system(size: 48, weight: .ultraLight, design: .default))
                                    .foregroundColor(.textMainHex)
                                    .tracking(2.0)
                                    .opacity(showTitle ? 1 : 0)
                                    .offset(y: showTitle ? 0 : 20)
                                    .animation(.easeOut(duration: 0.7).delay(0.3), value: showTitle)
                                Text("Your mindful companion for daily reflection")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(.mediumGreyHex)
                                    .multilineTextAlignment(.center)
                                    .tracking(0.5)
                                    .lineSpacing(2)
                                    .opacity(showSubtitle ? 1 : 0)
                                    .offset(y: showSubtitle ? 0 : 20)
                                    .animation(.easeOut(duration: 0.7).delay(0.6), value: showSubtitle)
                            }
                        }
                        // Benefits section
                        VStack(spacing: 24) {
                            HStack(spacing: 16) {
                                FeaturePill(
                                    icon: "brain.head.profile",
                                    text: "AI Insights",
                                    gradient: [.blue.opacity(0.8), .purple.opacity(0.6)]
                                )
                                .opacity(showPills ? 1 : 0)
                                .offset(y: showPills ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.9), value: showPills)
                                FeaturePill(
                                    icon: "target",
                                    text: "Goal Tracking",
                                    gradient: [.green.opacity(0.8), .blue.opacity(0.6)]
                                )
                                .opacity(showPills ? 1 : 0)
                                .offset(y: showPills ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(1.1), value: showPills)
                            }
                            HStack(spacing: 16) {
                                FeaturePill(
                                    icon: "chart.line.uptrend.xyaxis",
                                    text: "Mood Patterns",
                                    gradient: [.orange.opacity(0.8), .red.opacity(0.6)]
                                )
                                .opacity(showPills ? 1 : 0)
                                .offset(y: showPills ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(1.3), value: showPills)
                                FeaturePill(
                                    icon: "heart.fill",
                                    text: "Mindful Habits",
                                    gradient: [.pink.opacity(0.8), .purple.opacity(0.6)]
                                )
                                .opacity(showPills ? 1 : 0)
                                .offset(y: showPills ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(1.5), value: showPills)
                            }
                        }
                    }
                    Spacer()
                    // Get started button
                    VStack(spacing: 24) {
                        Button(action: {
                            showingOnboarding = true
                            HapticManager.shared.lightImpact()
                        }) {
                            HStack(spacing: 12) {
                                Text("Get Started")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.9),
                                        Color.purple.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .scaleEffect(buttonScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0.5).delay(1.7)) {
                                buttonScale = 1.05
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.spring()) { buttonScale = 1.0 }
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 0.15)) { buttonScale = 0.96 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.spring()) { buttonScale = 1.0 }
                            }
                        }
                        // Privacy note
                        Text("Your data stays private and secure")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.mediumGreyHex)
                            .opacity(0.8)
                    }
                    // Bottom safe area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: geometry.safeAreaInsets.bottom + 32)
                }
                .padding(.horizontal, 32)
                .onAppear {
                    // Animate in sequence
                    showTitle = false
                    showSubtitle = false
                    showPills = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showTitle = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showSubtitle = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { showPills = true }
                }
            }
            .background(Color.backgroundHex)
            .ignoresSafeArea(.all, edges: .top)
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingFlow()
        }
    }
}

// MARK: - Feature Pill Component

struct FeaturePill: View {
    let icon: String
    let text: String
    let gradient: [Color]
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
    }
}

#Preview {
    WelcomeView()
} 