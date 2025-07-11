import SwiftUI

struct TrialPaywallView: View {
    let onStartTrial: () -> Void
    let onSkip: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var animateContent = false
    @State private var animateFeatures = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top safe area padding
                Rectangle()
                    .fill(Color.backgroundHex)
                    .frame(height: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(.all, edges: .top)
                
                // Main content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                        
                        // Hero section
                        heroSection
                        
                        // Features
                        featuresSection
                        
                        // Trial benefits
                        trialBenefitsSection
                        
                        // Call to action
                        ctaSection
                        
                        // Skip option
                        skipSection
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 32)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.backgroundHex,
                        Color.blue.opacity(0.06),
                        Color.purple.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(.all, edges: .top)
            .onAppear {
                animateContent = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateFeatures = true
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.textMainHex)
            }
            
            Spacer()
            
            Text("flect premium")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.mediumGreyHex)
            
            Spacer()
            
            // Invisible spacer for symmetry
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.clear)
        }
        .padding(.top, 24)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : -20)
        .animation(.easeOut(duration: 0.6), value: animateContent)
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Premium icon
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [
                        Color.blue.opacity(0.9),
                        Color.purple.opacity(0.8),
                        Color.pink.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: .blue.opacity(0.3), radius: 16, x: 0, y: 8)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animateContent)
            
            VStack(spacing: 16) {
                Text("Unlock your full potential")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.textMainHex)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
                
                Text("Start your 7-day free trial and discover advanced insights, personalized AI coaching, and unlimited reflection.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 30)
            .animation(.easeOut(duration: 0.8).delay(0.4), value: animateContent)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 20) {
            ForEach(premiumFeatures.indices, id: \.self) { index in
                PremiumFeatureCard(feature: premiumFeatures[index])
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(x: animateFeatures ? 0 : -50)
                    .animation(
                        .easeOut(duration: 0.6).delay(Double(index) * 0.1),
                        value: animateFeatures
                    )
            }
        }
    }
    
    // MARK: - Trial Benefits
    
    private var trialBenefitsSection: some View {
        VStack(spacing: 20) {
            Text("Your 7-day trial includes:")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.textMainHex)
            
            VStack(spacing: 12) {
                TrialBenefitRow(icon: "checkmark.circle.fill", text: "All premium features unlocked", color: .green)
                TrialBenefitRow(icon: "clock.fill", text: "7 full days to explore", color: .blue)
                TrialBenefitRow(icon: "xmark.circle.fill", text: "Cancel anytime, no commitment", color: .orange)
                TrialBenefitRow(icon: "creditcard.fill", text: "No charge until trial ends", color: .purple)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackgroundHex)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(animateFeatures ? 1 : 0)
        .offset(y: animateFeatures ? 0 : 20)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateFeatures)
    }
    
    // MARK: - Call to Action
    
    private var ctaSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                HapticManager.shared.success()
                onStartTrial()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Start 7-Day Free Trial")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
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
                .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(animateFeatures ? 1 : 0.95)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateFeatures)
            
            Text("Then $9.99/month • Cancel anytime")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.mediumGreyHex)
                .opacity(animateFeatures ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(1.0), value: animateFeatures)
        }
    }
    
    // MARK: - Skip Section
    
    private var skipSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                HapticManager.shared.lightImpact()
                onSkip()
            }) {
                Text("Continue with basic features")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.mediumGreyHex)
                    .underline()
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("You can upgrade anytime in settings")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.mediumGreyHex.opacity(0.7))
        }
        .opacity(animateFeatures ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(1.2), value: animateFeatures)
    }
}

// MARK: - Premium Features Data

private let premiumFeatures: [PremiumFeature] = [
    PremiumFeature(
        icon: "brain.head.profile",
        title: "AI-Powered Insights",
        description: "Advanced pattern recognition and personalized recommendations based on your unique behavioral data.",
        color: .purple
    ),
    PremiumFeature(
        icon: "chart.line.uptrend.xyaxis",
        title: "Advanced Analytics",
        description: "Deep mood trends, correlation analysis, and predictive insights to optimize your wellbeing.",
        color: .blue
    ),
    PremiumFeature(
        icon: "text.bubble.fill",
        title: "Unlimited Journaling",
        description: "Express yourself freely with unlimited journal entries and smart sentiment analysis.",
        color: .green
    ),
    PremiumFeature(
        icon: "target",
        title: "Personalized Goals",
        description: "AI-crafted wellness goals that adapt to your progress and personality type.",
        color: .orange
    ),
    PremiumFeature(
        icon: "clock.arrow.circlepath",
        title: "Historical Exports",
        description: "Export your data, access extended history, and never lose your journey.",
        color: .pink
    )
]

// MARK: - Supporting Views

struct PremiumFeatureCard: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [
                        feature.color.opacity(0.8),
                        feature.color.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: feature.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textMainHex)
                
                Text(feature.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.mediumGreyHex)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackgroundHex)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(feature.color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: feature.color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct TrialBenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textMainHex)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Types

struct PremiumFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    TrialPaywallView(
        onStartTrial: { print("Start trial") },
        onSkip: { print("Skip trial") }
    )
} 