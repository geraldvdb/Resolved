//
//  RewardPopupView.swift
//  Resolved
//
//  Celebratory popup when a reward is unlocked
//

import SwiftUI

struct RewardPopupView: View {
    @Environment(\.colorScheme) private var colorScheme
    let reward: Reward
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Confetti layer
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            // Content card
            VStack(spacing: 24) {
                // Trophy icon with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppColors.gold.opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: reward.triggerIcon)
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.gold, AppColors.goldLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(rotation))
                        .shadow(color: AppColors.gold.opacity(0.5), radius: 20)
                }
                
                // Title
                Text("Reward Unlocked!")
                    .font(.custom("Avenir Next", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                
                // Trigger info
                Text(reward.triggerDisplayName)
                    .font(.custom("Avenir Next", size: 14))
                    .foregroundColor(AppColors.primaryText(colorScheme).opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.primaryText(colorScheme).opacity(0.1))
                    .cornerRadius(20)
                
                // Reward description
                Text(reward.descriptionText)
                    .font(.custom("Avenir Next", size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Celebrate button
                Button(action: dismissWithAnimation) {
                    HStack {
                        Image(systemName: "hands.clap.fill")
                        Text("Celebrate!")
                    }
                    .font(.custom("Avenir Next", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.accentGradient)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.cardBackground(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [AppColors.gold.opacity(0.5), AppColors.accent.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: AppColors.gold.opacity(0.3), radius: 30)
            .padding(40)
            .scaleEffect(showContent ? 1 : 0.5)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                showConfetti = true
            }
            // Subtle rotation animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                rotation = 10
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
            showConfetti = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Guard against invalid size
                guard size.width > 0 && size.height > 0 else { return }
                
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                
                for particle in particles {
                    let age = currentTime - particle.createdAt
                    let progress = age / particle.lifetime
                    
                    guard progress < 1 else { continue }
                    
                    let x = particle.startX + particle.velocityX * age
                    let y = particle.startY + particle.velocityY * age + 200 * age * age // gravity
                    let opacity = 1 - progress
                    let rotationAngle = particle.rotation + particle.rotationSpeed * age
                    
                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .radians(rotationAngle))
                    
                    let rect = CGRect(x: -particle.size/2, y: -particle.size/2, width: particle.size, height: particle.size)
                    context.fill(Path(rect), with: .color(particle.color))
                    
                    context.rotate(by: .radians(-rotationAngle))
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [
            AppColors.gold,
            AppColors.accent,
            Color(hex: "00d9ff"),
            Color(hex: "00ff88"),
            AppColors.accentLight,
            AppColors.goldLight
        ]
        
        let screenWidth = UIScreen.main.bounds.width
        let currentTime = Date().timeIntervalSinceReferenceDate
        
        for _ in 0..<80 {
            let particle = ConfettiParticle(
                startX: CGFloat.random(in: 0...screenWidth),
                startY: CGFloat.random(in: -100...0),
                velocityX: CGFloat.random(in: -100...100),
                velocityY: CGFloat.random(in: 50...200),
                rotation: Double.random(in: 0...Double.pi * 2),
                rotationSpeed: Double.random(in: -5...5),
                size: CGFloat.random(in: 6...14),
                color: colors.randomElement()!,
                lifetime: Double.random(in: 2...4),
                createdAt: currentTime
            )
            particles.append(particle)
        }
    }
}

struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let size: CGFloat
    let color: Color
    let lifetime: Double
    let createdAt: TimeInterval
}

#Preview {
    RewardPopupView(
        reward: Reward(descriptionText: "Treat yourself to a nice dinner!", triggerType: "segment", triggerValue: 10),
        onDismiss: {}
    )
}
