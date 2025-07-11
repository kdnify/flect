import SwiftUI

struct MultiStepCheckInView: View {
    enum Step: Int, CaseIterable {
        case mood, energy, sleep, social, highlight, note, summary
    }
    
    @State private var step: Step = .mood
    @State private var mood: Int? = nil // 0-4
    @State private var energy: Int? = nil // 0=Low, 1=Med, 2=High
    @State private var sleep: Int? = nil // 0=Bad, 1=OK, 2=Great
    @State private var social: Int? = nil // 0=Alone, 1=Some, 2=With Others
    @State private var highlight: String? = nil
    @State private var note: String = ""
    
    // For summary
    private var wellbeingScore: Int {
        (energy ?? 0) - 1 + (sleep ?? 0) - 1 + (social ?? 0) - 1 + ((highlight != nil) ? 1 : 0)
    }
    private var dotColor: Color {
        if wellbeingScore >= 2 { return .green }
        if wellbeingScore >= 0 { return .yellow }
        return .red
    }
    
    // Mood options (on-brand, not emoji)
    private let moodOptions: [(String, [Color])] = [
        ("face.dashed", [Color.red.opacity(0.8), Color.pink.opacity(0.6)]),         // Terrible
        ("face.frown", [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),        // Bad
        ("face.neutral", [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),       // Neutral
        ("face.smiling.inverse", [Color.blue.opacity(0.8), Color.green.opacity(0.6)]), // Good
        ("face.smiling", [Color.purple.opacity(0.8), Color.blue.opacity(0.6)])      // Excellent
    ]
    
    private static let highlightOptions: [HighlightOption] = [
        HighlightOption(tag: "Exercise", gradient: [Color.orange.opacity(0.8), Color.purple.opacity(0.6)]),
        HighlightOption(tag: "Food", gradient: [Color.green.opacity(0.8), Color.blue.opacity(0.6)]),
        HighlightOption(tag: "Family", gradient: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)]),
        HighlightOption(tag: "Nature", gradient: [Color.green.opacity(0.8), Color.orange.opacity(0.6)]),
        HighlightOption(tag: "Work", gradient: [Color.blue.opacity(0.8), Color.gray.opacity(0.6)]),
        HighlightOption(tag: "Creative", gradient: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)])
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundHex.ignoresSafeArea()
            VStack(spacing: 32) {
                // Progress Dots
                HStack(spacing: 8) {
                    ForEach(0..<Step.summary.rawValue, id: \ .self) { idx in
                        Circle()
                            .fill(idx == step.rawValue ? Color.accentHex : Color.accentHex.opacity(0.18))
                            .frame(width: 8, height: 8)
                    }
                }
                // Card
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: cardGradient(for: step)),
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .shadow(color: Color.accentHex.opacity(0.08), radius: 12, x: 0, y: 4)
                    VStack(spacing: 28) {
                        stepContent
                    }
                    .padding(32)
                }
                Spacer()
            }
            .padding()
            .animation(.easeInOut, value: step)
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .mood: moodStep
        case .energy: energyStep
        case .sleep: sleepStep
        case .social: socialStep
        case .highlight: highlightStep
        case .note: noteStep
        case .summary: summaryStep
        }
    }
    
    private var moodStep: some View {
        VStack(spacing: 28) {
            Text("How are you feeling?")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.accentHex)
            HStack(spacing: 24) {
                ForEach(0..<moodOptions.count, id: \.self) { i in
                    let option = moodOptions[i]
                    let icon = option.0
                    let grad = option.1
                    Button(action: { mood = i; next() }) {
                        ZStack {
                            let gradient = LinearGradient(gradient: Gradient(colors: grad), startPoint: .topLeading, endPoint: .bottomTrailing)
                            Circle()
                                .fill(gradient)
                                .frame(width: 64, height: 64)
                            Image(systemName: icon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .shadow(color: grad.first?.opacity(0.18) ?? .clear, radius: 6, x: 0, y: 2)
                    }
                }
            }
        }
    }
    
    private var energyStep: some View {
        VStack(spacing: 28) {
            Text("How's your energy?")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.accentHex)
            
            HStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { i in
                    EnergyOptionView(index: i, energy: $energy, onSelect: next)
                }
            }
        }
    }
    
    private var sleepStep: some View {
        VStack(spacing: 28) {
            Text("How did you sleep?")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.accentHex)
            
            HStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { i in
                    SleepOptionView(index: i, sleep: $sleep, onSelect: next)
                }
            }
        }
    }
    
    private var socialStep: some View {
        VStack(spacing: 28) {
            Text("Did you spend time with others?")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.accentHex)
            
            HStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { i in
                    SocialOptionView(index: i, social: $social, onSelect: next)
                }
            }
        }
    }
    
    private var highlightStep: some View {
        VStack(spacing: 28) {
            Text("What was the highlight of your day?")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.accentHex)
            HighlightOptionsRow(
                options: Self.highlightOptions,
                selected: highlight,
                onSelect: { tag in highlight = tag; next() }
            )
        }
    }
    
    private var noteStep: some View {
        VStack(spacing: 28) {
            Text("Anything else you want to remember?")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.accentHex)
            TextField("Optional note", text: $note)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 8)
            Button("Next") { next() }
                .buttonStyle(.borderedProminent)
                .tint(.accentHex)
                .clipShape(Capsule())
        }
    }
    
    private var summaryStep: some View {
        VStack(spacing: 28) {
            Text("Check-In Complete!")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(.accentHex)
            Text("Your wellbeing dot:")
            Circle().fill(dotColor).frame(width: 40, height: 40)
            Text("Mood: \(moodLabel)\nEnergy: \(energyLabel)\nSleep: \(sleepLabel)\nSocial: \(socialLabel)\nHighlight: \(highlight ?? "None")")
                .multilineTextAlignment(.center)
            Button("Done") { 
                // Save check-in data and dismiss
                saveCheckIn()
                NotificationCenter.default.post(name: Notification.Name("checkInCompleted"), object: nil)
            }
                .buttonStyle(.borderedProminent)
                .tint(.accentHex)
                .clipShape(Capsule())
        }
    }
    
    private func next() {
        if let nextStep = Step(rawValue: step.rawValue + 1) {
            step = nextStep
        }
    }
    private func cardGradient(for step: Step) -> [Color] {
        switch step {
        case .mood: return [Color.purple.opacity(0.08), Color.blue.opacity(0.04)]
        case .energy: return [Color.orange.opacity(0.08), Color.red.opacity(0.04)]
        case .sleep: return [Color.blue.opacity(0.08), Color.purple.opacity(0.04)]
        case .social: return [Color.green.opacity(0.08), Color.blue.opacity(0.04)]
        case .highlight: return [Color.pink.opacity(0.08), Color.orange.opacity(0.04)]
        case .note: return [Color.gray.opacity(0.08), Color.backgroundHex]
        case .summary: return [Color.accentHex.opacity(0.12), Color.backgroundHex]
        }
    }
    private var moodLabel: String {
        let moods = ["Terrible", "Bad", "Neutral", "Good", "Excellent"]
        return moods[mood ?? 2]
    }
    private var energyLabel: String { ["Low","Medium","High"][energy ?? 1] }
    private var sleepLabel: String { ["Bad","Okay","Great"][sleep ?? 1] }
    private var socialLabel: String { ["Alone","Some","With Others"][social ?? 1] }
    
    // MARK: - Save Function
    private func saveCheckIn() {
        // Submit check-in using the existing service
        Task {
            do {
                _ = try await CheckInService.shared.submitCheckIn(
                    happyThing: highlight ?? "No specific highlight",
                    improveThing: note.isEmpty ? "No specific improvements noted" : note,
                    moodName: moodLabel,
                    energy: energy,
                    sleep: sleep,
                    social: social,
                    highlight: highlight,
                    wellbeingScore: wellbeingScore
                )
                NotificationCenter.default.post(name: Notification.Name("checkInCompleted"), object: nil)
            } catch {
                print("Error saving check-in: \(error)")
            }
        }
    }
}

// MARK: - Helper Views

struct HighlightOption: Hashable {
    let tag: String
    let gradient: [Color]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
    }
    static func == (lhs: HighlightOption, rhs: HighlightOption) -> Bool {
        lhs.tag == rhs.tag
    }
}

struct EnergyOptionView: View {
    let index: Int
    @Binding var energy: Int?
    let onSelect: () -> Void
    
    private var label: String {
        ["Low","Medium","High"][index]
    }
    
    private var icon: String {
        ["battery.25","battery.50","battery.100"][index]
    }
    
    private var gradient: LinearGradient {
        let colors = [
            [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
            [Color.blue.opacity(0.8), Color.green.opacity(0.6)],
            [Color.green.opacity(0.8), Color.blue.opacity(0.6)]
        ][index]
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        Button(action: { energy = index; onSelect() }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
            }
        }
    }
}

struct SleepOptionView: View {
    let index: Int
    @Binding var sleep: Int?
    let onSelect: () -> Void
    
    private var label: String {
        ["Bad","Okay","Great"][index]
    }
    
    private var icon: String {
        ["zzz","moon","sparkles"][index]
    }
    
    private var gradient: LinearGradient {
        let colors = [
            [Color.red.opacity(0.7), Color.orange.opacity(0.5)],
            [Color.blue.opacity(0.7), Color.purple.opacity(0.5)],
            [Color.green.opacity(0.7), Color.blue.opacity(0.5)]
        ][index]
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        Button(action: { sleep = index; onSelect() }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
            }
        }
    }
}

struct SocialOptionView: View {
    let index: Int
    @Binding var social: Int?
    let onSelect: () -> Void
    
    private var label: String {
        ["Alone","Some","With Others"][index]
    }
    
    private var icon: String {
        ["person","person.2","person.3"][index]
    }
    
    private var gradient: LinearGradient {
        let colors = [
            [Color.gray.opacity(0.7), Color.purple.opacity(0.5)],
            [Color.blue.opacity(0.7), Color.green.opacity(0.5)],
            [Color.green.opacity(0.7), Color.blue.opacity(0.5)]
        ][index]
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        Button(action: { social = index; onSelect() }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
            }
        }
    }
}

struct HighlightOptionView: View {
    let tag: String
    let gradient: [Color]
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var linearGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: gradient), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        Button(action: onSelect) {
            Text(tag)
                .font(.subheadline)
                .foregroundColor(.textMainHex)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    linearGradient.opacity(isSelected ? 0.7 : 0.18)
                )
                .cornerRadius(18)
                .shadow(color: gradient.first?.opacity(0.12) ?? .clear, radius: 4, x: 0, y: 2)
        }
    }
}

// Helper for wrapping tags
struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content
    init(_ data: Data, id: KeyPath<Data.Element, Data.Element>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(Array(data), id: \ .self) { item in
                    content(item)
                        .padding([.horizontal, .vertical], 4)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geometry.size.width {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == data.last { width = 0 } else { width -= d.width }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == data.last { height = 0 } else { }
                            return result
                        }
                }
            }
        }
        .frame(height: 44)
    }
}

struct HighlightOptionsRow: View {
    let options: [HighlightOption]
    let selected: String?
    let onSelect: (String) -> Void
    
    var body: some View {
        WrapHStack(options, id: \.self) { option in
            HighlightOptionView(
                tag: option.tag,
                gradient: option.gradient,
                isSelected: selected == option.tag,
                onSelect: { onSelect(option.tag) }
            )
        }
    }
} 