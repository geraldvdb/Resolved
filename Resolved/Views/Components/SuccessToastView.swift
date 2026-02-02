//
//  SuccessToastView.swift
//  Resolved
//
//  A brief celebratory toast that appears after logging progress
//

import SwiftUI

struct SuccessToastView: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: String
    let onComplete: () -> Void
    
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 12) {
                    // Checkmark icon with circle background
                    ZStack {
                        Circle()
                            .fill(AppColors.success(colorScheme).opacity(AppColors.subtleBackgroundOpacity(colorScheme, base: 0.2)))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.success(colorScheme))
                    }
                    
                    Text(message)
                        .font(.custom("Avenir Next", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryText(colorScheme))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AppColors.cardBackground(colorScheme))
                        .shadow(color: AppColors.cardShadow(colorScheme), radius: 10, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(AppColors.success(colorScheme).opacity(AppColors.borderOpacity(colorScheme, base: 0.3)), lineWidth: 1)
                )
                .scaleEffect(scale)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
                scale = 1.0
            }
            
            // Auto-dismiss after delay (~1s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                    scale = 0.8
                }
                
                // Call completion after animation finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.background(.dark)
            .ignoresSafeArea()
        
        SuccessToastView(message: "Well done!") {
            print("Toast completed")
        }
    }
}
