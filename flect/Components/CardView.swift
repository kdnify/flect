import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(Color.cardBackgroundHex)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    CardView {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Card")
                .font(.headline)
                .foregroundColor(.textMainHex)
            
            Text("This is a basic card component used throughout the app for consistent styling.")
                .font(.body)
                .foregroundColor(.mediumGreyHex)
        }
    }
    .padding()
    .background(Color.backgroundHex)
} 