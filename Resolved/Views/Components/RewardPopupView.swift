//
//  RewardPopupView.swift
//  Resolved
//
//  Celebratory popup when a reward is unlocked - with interactive reveal
//

import SwiftUI

struct RewardPopupView: View {
    @Environment(\.colorScheme) private var colorScheme
    let reward: Reward
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var isRevealed = false
    @State private var giftShake: CGFloat = 0
    @State private var giftScale: CGFloat = 1.0
    @State private var glowPulse: Double = 0.4
    @State private var rewardScale: CGFloat = 0.3
    @State private var rewardOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    if isRevealed {
                        dismissWithAnimation()
                    }
                }
            
            // Confetti layer
            if showConfetti {
                ConfettiView(colorScheme: colorScheme)
                    .ignoresSafeArea()
            }
            
            // Content
            if !isRevealed {
                // Phase 1: Gift box reveal
                giftBoxView
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)
            } else {
                // Phase 2: Revealed reward
                revealedRewardView
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                showConfetti = true
            }
            startGiftAnimations()
        }
    }
    
    // MARK: - Phase 1: Gift Box
    
    private var giftBoxView: some View {
        VStack(spacing: 24) {
            // Gift box icon with glow
            ZStack {
                // Pulsing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.gold(colorScheme).opacity(glowPulse), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Gift box
                Image(systemName: "gift.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.gold(colorScheme), AppColors.goldLight(colorScheme)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(giftShake))
                    .scaleEffect(giftScale)
                    .shadow(color: AppColors.gold(colorScheme).opacity(0.5), radius: 20)
            }
            
            // Title
            Text("Reward Unlocked!")
                .font(.custom("Avenir Next", size: 28))
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText(colorScheme))
            
            // Tap to reveal prompt
            VStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.gold(colorScheme).opacity(0.8))
                
                Text("Tap to reveal your reward")
                    .font(.custom("Avenir Next", size: 16))
                    .foregroundColor(AppColors.secondaryText(colorScheme))
            }
            .padding(.top, 8)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.cardBackground(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.gold(colorScheme).opacity(0.5), AppColors.accent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: AppColors.gold(colorScheme).opacity(0.3), radius: 30)
        .padding(40)
        .onTapGesture {
            revealReward()
        }
    }
    
    // MARK: - Phase 2: Revealed Reward
    
    private var revealedRewardView: some View {
        VStack(spacing: 24) {
            // Reward icon with burst effect
            ZStack {
                // Burst rays
                ForEach(0..<8, id: \.self) { index in
                    Rectangle()
                        .fill(AppColors.gold(colorScheme).opacity(0.3))
                        .frame(width: 4, height: 60)
                        .offset(y: -60)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
                .scaleEffect(rewardScale)
                .opacity(rewardOpacity)
                
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.gold(colorScheme).opacity(0.6), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                // Reward icon
                Image(systemName: reward.triggerIcon)
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.gold(colorScheme), AppColors.goldLight(colorScheme)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(rewardScale)
                    .shadow(color: AppColors.gold(colorScheme).opacity(0.5), radius: 20)
            }
            
            // Title
            Text("Your Reward")
                .font(.custom("Avenir Next", size: 16))
                .foregroundColor(AppColors.secondaryText(colorScheme))
                .opacity(rewardOpacity)
            
            // Reward description - the main reveal
            Text(reward.descriptionText)
                .font(.custom("Avenir Next", size: 24))
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .scaleEffect(rewardScale)
                .opacity(rewardOpacity)
            
            // Trigger info badge
            Text(reward.triggerDisplayName)
                .font(.custom("Avenir Next", size: 14))
                .foregroundColor(AppColors.gold(colorScheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.gold(colorScheme).opacity(AppColors.subtleBackgroundOpacity(colorScheme, base: 0.15)))
                .cornerRadius(20)
                .opacity(rewardOpacity)
            
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
            .padding(.top, 8)
            .opacity(rewardOpacity)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.cardBackground(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.gold(colorScheme).opacity(0.5), AppColors.accent.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: AppColors.gold(colorScheme).opacity(0.3), radius: 30)
        .padding(40)
    }
    
    // MARK: - Animations
    
    private func startGiftAnimations() {
        // Shake animation
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            giftShake = 3
        }
        
        // Pulse glow
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowPulse = 0.7
        }
        
        // Subtle scale pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.3)) {
            giftScale = 1.05
        }
    }
    
    private func revealReward() {
        // Stop gift animations and transition
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            giftScale = 1.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showContent = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isRevealed = true
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showContent = true
                }
                
                // Animate reward reveal
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                    rewardScale = 1.0
                    rewardOpacity = 1.0
                }
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
    let colorScheme: ColorScheme
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
            AppColors.gold(colorScheme),
            AppColors.accent,
            Color(hex: "00d9ff"),
            Color(hex: "00ff88"),
            AppColors.accentLight,
            AppColors.goldLight(colorScheme)
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
