import SwiftUI

struct EnhancedLoadingView: View {
    let stage: ProcessingStage
    @State private var animationPhase = 0.0
    @State private var pulseScale = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.2),
                            Color.purple.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                
                Image(systemName: stage.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(stage.iconColor)
                    .rotationEffect(.degrees(animationPhase))
                    .animation(
                        Animation.linear(duration: 2.0)
                            .repeatForever(autoreverses: false),
                        value: animationPhase
                    )
            }
            
            // Status Text
            VStack(spacing: 8) {
                Text(stage.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(stage.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress Bar
            ProgressBarView(stage: stage)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveCardBackground)
                .shadow(color: Color.adaptiveColor(light: "000000", dark: "FFFFFF").opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            pulseScale = 1.2
            animationPhase = 360
        }
    }
}

struct ProgressBarView: View {
    let stage: ProcessingStage
    @State private var progress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress Steps
            HStack(spacing: 12) {
                ForEach(ProcessingStage.allCases.indices, id: \.self) { index in
                    let stepStage = ProcessingStage.allCases[index]
                    let isCompleted = stepStage.rawValue <= stage.rawValue
                    let isCurrent = stepStage == stage
                    
                    HStack(spacing: 8) {
                        // Step Circle
                        ZStack {
                            Circle()
                                .fill(isCompleted ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                            
                            if isCompleted && !isCurrent {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else if isCurrent {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        // Step Title
                        if index < ProcessingStage.allCases.count - 1 {
                            Text(stepStage.shortTitle)
                                .font(.caption)
                                .foregroundColor(isCompleted ? .primary : .secondary)
                            
                            // Connecting Line
                            Rectangle()
                                .fill(isCompleted ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(stepStage.shortTitle)
                                .font(.caption)
                                .foregroundColor(isCompleted ? .primary : .secondary)
                        }
                    }
                }
            }
            
            // Overall Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 4)
        }
        .onAppear {
            progress = stage.progressValue
        }
        .onChange(of: stage) { newStage in
            withAnimation(.easeInOut(duration: 0.5)) {
                progress = newStage.progressValue
            }
        }
    }
}

enum ProcessingStage: Int, CaseIterable {
    case transcribing = 0
    case processing = 1
    case extracting = 2
    case complete = 3
    
    // Text-only processing stages (skip transcribing)
    static var textProcessingStages: [ProcessingStage] {
        [.processing, .extracting, .complete]
    }
    
    var iconName: String {
        switch self {
        case .transcribing: return "mic.fill"
        case .processing: return "brain.head.profile"
        case .extracting: return "list.bullet.clipboard"
        case .complete: return "checkmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .transcribing: return .red
        case .processing: return .purple
        case .extracting: return .blue
        case .complete: return .green
        }
    }
    
    var title: String {
        switch self {
        case .transcribing: return "Transcribing Audio"
        case .processing: return "Processing with AI"
        case .extracting: return "Extracting Tasks"
        case .complete: return "Complete!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .transcribing: return "Converting your voice to text..."
        case .processing: return "Understanding your thoughts with AI..."
        case .extracting: return "Finding actionable tasks..."
        case .complete: return "Ready to review your tasks!"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .transcribing: return "Transcribe"
        case .processing: return "Process"
        case .extracting: return "Extract"
        case .complete: return "Done"
        }
    }
    
    var progressValue: CGFloat {
        switch self {
        case .transcribing: return 0.25
        case .processing: return 0.65
        case .extracting: return 0.9
        case .complete: return 1.0
        }
    }
    
    var progress: Double {
        switch self {
        case .transcribing: return 0.33
        case .processing: return 0.66
        case .extracting: return 1.0
        case .complete: return 1.0
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        EnhancedLoadingView(stage: .transcribing)
        EnhancedLoadingView(stage: .processing)
        EnhancedLoadingView(stage: .extracting)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 