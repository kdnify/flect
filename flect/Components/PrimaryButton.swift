import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color.adaptiveTextSecondary : Color.adaptivePrimary)
            )
        }
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(isDisabled ? .adaptiveTextSecondary : .adaptivePrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDisabled ? Color.adaptiveTextSecondary : Color.adaptivePrimary, lineWidth: 2)
                        .fill(Color.adaptiveBackground)
                )
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Primary Button") {
            print("Primary tapped")
        }
        
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        
        SecondaryButton(title: "Secondary Button") {
            print("Secondary tapped")
        }
    }
    .padding()
} 