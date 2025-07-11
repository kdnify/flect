import SwiftUI

struct InsightDetailView: View {
    let insight: UserInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: insight.type.icon)
                                .font(.title)
                                .foregroundColor(.accentHex)
                            
                            Text(insight.type.displayName)
                                .font(.headline)
                                .foregroundColor(.mediumGreyHex)
                        }
                        
                        Text(insight.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textMainHex)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Description
                    Text(insight.description)
                        .font(.body)
                        .foregroundColor(.textMainHex)
                        .multilineTextAlignment(.center)
                    
                    // Confidence indicator
                    VStack(spacing: 8) {
                        Text("Confidence Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.mediumGreyHex)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Circle()
                                    .fill(index < Int(insight.confidence * 5) ? Color.accentHex : Color.cardBackgroundHex)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        
                        Text(confidenceLevelText)
                            .font(.caption)
                            .foregroundColor(.mediumGreyHex)
                    }
                    
                    // Data points
                    VStack(spacing: 8) {
                        Text("Based on")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.mediumGreyHex)
                        
                        Text("\(insight.dataPoints) data points")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.textMainHex)
                    }
                    
                    // Metadata visualization
                    if let metadata = insight.metadata {
                        metadataSection(metadata)
                    }
                    
                    // Related insights
                    if !relatedInsights.isEmpty {
                        relatedInsightsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.backgroundHex)
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var confidenceLevelText: String {
        if insight.confidence >= 0.8 {
            return "High confidence - strong pattern detected"
        } else if insight.confidence >= 0.6 {
            return "Medium confidence - likely pattern"
        } else {
            return "Low confidence - emerging pattern"
        }
    }
    
    @ViewBuilder
    private func metadataSection(_ metadata: InsightMetadata) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            // Frequency data visualization
            if let frequencyData = metadata.frequencyData {
                VStack(spacing: 12) {
                    ForEach(Array(frequencyData.sorted(by: { $0.value > $1.value })), id: \.key) { key, value in
                        FrequencyDataRow(
                            label: key.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
                                .trimmingCharacters(in: .whitespaces)
                                .capitalized,
                            value: value
                        )
                    }
                }
            }
            
            // Keywords
            if let keywords = metadata.keywords, !keywords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Related Keywords")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(keywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .foregroundColor(.accentHex)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentHex.opacity(0.1))
                                )
                        }
                    }
                }
            }
            
            // Time patterns
            if let timePatterns = metadata.timePatterns, !timePatterns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Patterns")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textMainHex)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(timePatterns.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                            Text("• \(key): \(value)")
                                .font(.caption)
                                .foregroundColor(.mediumGreyHex)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
    }
    
    private var relatedInsights: [UserInsight] {
        PatternAnalysisService.shared.insights.filter { insight in
            insight.id != self.insight.id && insight.type == self.insight.type
        }
    }
    
    private var relatedInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.textMainHex)
            
            VStack(spacing: 12) {
                ForEach(relatedInsights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding(20)
        .background(Color.cardBackgroundHex)
        .cornerRadius(16)
    }
}

// MARK: - Supporting Views

struct FrequencyDataRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.textMainHex)
                
                Spacer()
                
                Text("\(value)%")
                    .font(.caption)
                    .foregroundColor(.mediumGreyHex)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.cardBackgroundHex)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.accentHex)
                        .frame(width: geometry.size.width * CGFloat(value) / 100.0, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        
        height = currentY + currentRowHeight
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(size)
            )
            
            currentX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

// MARK: - Preview

struct InsightDetailView_Previews: PreviewProvider {
    static var previews: some View {
        InsightDetailView(insight: UserInsight(
            type: .pattern,
            title: "Sample Insight",
            description: "This is a sample insight description that shows how the detail view looks.",
            confidence: 0.8,
            dataPoints: 42,
            metadata: InsightMetadata(
                frequencyData: [
                    "morningRate": 75,
                    "afternoonRate": 50,
                    "eveningRate": 25
                ],
                keywords: ["Sleep", "Energy", "Mood"],
                timePatterns: [
                    "Morning": "High productivity",
                    "Evening": "Low energy"
                ]
            )
        ))
    }
} 