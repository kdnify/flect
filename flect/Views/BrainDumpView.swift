import SwiftUI

struct BrainDumpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: JournalViewModel
    
    @State private var brainDumpText = ""
    @State private var selectedMood: Mood = .neutral
    @State private var showingMoodPicker = false
    
    private var isReadyToProcess: Bool {
        !brainDumpText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Instructions
                        instructionsSection
                        
                        // Brain dump input
                        brainDumpInputSection
                        
                        // Mood selection
                        moodSelectionSection
                        
                        // Processing button
                        processButtonSection
                    }
                    .padding()
                }
                .background(Color.background)
            }
            .navigationBarHidden(true)
        }
        .overlay {
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .onDisappear {
            viewModel.loadData()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.mediumGrey)
            
            Spacer()
            
            Text("Brain Dump")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMain)
            
            Spacer()
            
            // Placeholder for balance
            Text("Cancel")
                .foregroundColor(.clear)
        }
        .padding()
        .background(Color.cardBackground)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clear your mind. Capture your day.")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textMain)
            
            Text("Write down whatever's on your mind - thoughts, tasks, feelings, ideas. Don't worry about structure or grammar. Just get it all out.")
                .font(.body)
                .foregroundColor(.mediumGrey)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var brainDumpInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's on your mind?")
                .font(.headline)
                .foregroundColor(.textMain)
            
            TextEditor(text: $brainDumpText)
                .font(.body)
                .foregroundColor(.textMain)
                .frame(minHeight: 200)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if brainDumpText.isEmpty {
                        Text("I need to finish that project by Friday, feeling stressed about it. Also should call mom this week, haven't talked to her in a while. Grateful for the sunny weather today though...")
                            .font(.body)
                            .foregroundColor(.mediumGrey.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
            
            // Character count
            HStack {
                Spacer()
                Text("\(brainDumpText.count) characters")
                    .font(.caption)
                    .foregroundColor(.mediumGrey)
            }
        }
    }
    
    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.headline)
                .foregroundColor(.textMain)
            
            Button(action: { showingMoodPicker.toggle() }) {
                HStack {
                    Text(selectedMood.rawValue)
                        .font(.title2)
                    
                    Text(selectedMood.displayName)
                        .font(.body)
                        .foregroundColor(.textMain)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.mediumGrey)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingMoodPicker {
                moodPickerGrid
            }
        }
    }
    
    private var moodPickerGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(Mood.allCases, id: \.self) { mood in
                Button(action: {
                    selectedMood = mood
                    showingMoodPicker = false
                }) {
                    VStack(spacing: 4) {
                        Text(mood.rawValue)
                            .font(.title2)
                        
                        Text(mood.displayName)
                            .font(.caption)
                            .foregroundColor(.textMain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedMood == mood ? Color.accent.opacity(0.2) : Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedMood == mood ? Color.accent : Color.borderColor, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
    
    private var processButtonSection: some View {
        VStack(spacing: 16) {
            PrimaryButton(
                title: "Process & Create Entry",
                action: processEntryAction,
                isLoading: viewModel.isProcessing,
                isDisabled: !isReadyToProcess || viewModel.isProcessing
            )
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.error)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    .scaleEffect(1.5)
                
                VStack(spacing: 8) {
                    Text("Processing your thoughts...")
                        .font(.headline)
                        .foregroundColor(.textMain)
                    
                    Text("AI is analyzing your brain dump and creating a structured journal entry")
                        .font(.body)
                        .foregroundColor(.mediumGrey)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
    
    private func processEntryAction() {
        _Concurrency.Task {
            await viewModel.processBrainDump(brainDumpText, mood: selectedMood.name)
            
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

#Preview {
    BrainDumpView(viewModel: JournalViewModel())
} 