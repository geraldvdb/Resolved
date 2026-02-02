//
//  StreakCelebrationView.swift
//  Resolved
//
//  Duolingo-inspired streak celebration with flame animation
//

import SwiftUI

struct StreakCelebrationView: View {
    @Environment(\.colorScheme) private var colorScheme
    let streakCount: Int
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var flameScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0.3
    @State private var numberOffset: CGFloat = 20
    @State private var showParticles = false
    
    // Flame colors
    private let flameOrange = Color(hex: "ff6b35")
    private let flameYellow = Color(hex: "ffd700")
    private let flameRed = Color(hex: "ff4444")
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
                .onAppear {
                    // Auto-dismiss after ~1.5s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismissWithAnimation()
                    }
                }
            
            // Flame particles
            if showParticles {
                FlameParticlesView()
                    .ignoresSafeArea()
            }
            
            // Main content
            VStack(spacing: 20) {
                Spacer()
                
                // Flame icon with glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [flameOrange.opacity(glowOpacity), Color.clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                    
                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [flameYellow.opacity(glowOpacity * 0.8), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    // Flame icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [flameYellow, flameOrange, flameRed],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(flameScale)
                        .shadow(color: flameOrange.opacity(0.8), radius: 20)
                }
                
                // Streak count
                VStack(spacing: 8) {
                    Text("\(streakCount)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [flameYellow, flameOrange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: flameOrange.opacity(0.5), radius: 10)
                        .offset(y: numberOffset)
                    
                    Text("day streak!")
                        .font(.custom("Avenir Next", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .offset(y: numberOffset)
                }
                
                Spacer()
                
                // Motivational text
                Text("You're on fire! Keep it going!")
                    .font(.custom("Avenir Next", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showContent ? 1 : 0)
                
                // Continue button
                Button(action: dismissWithAnimation) {
                    Text("Continue")
                        .font(.custom("Avenir Next", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [flameOrange, flameRed],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Main content fade in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showContent = true
        }
        
        // Flame scale animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            flameScale = 1.0
        }
        
        // Number slide up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            numberOffset = 0
        }
        
        // Particles
        withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
            showParticles = true
        }
        
        // Pulsing glow animation
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
            showParticles = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Flame Particles View

struct FlameParticlesView: View {
    @State private var particles: [FlameParticle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard size.width > 0 && size.height > 0 else { return }
                
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                
                for particle in particles {
                    let age = currentTime - particle.createdAt
                    let progress = age / particle.lifetime
                    
                    guard progress < 1 else { continue }
                    
                    // Particles rise up
                    let x = particle.startX + sin(age * particle.wobbleSpeed) * particle.wobbleAmount
                    let y = particle.startY - (particle.riseSpeed * age)
                    let opacity = (1 - progress) * particle.maxOpacity
                    let currentScale = particle.scale * (1 - progress * 0.5)
                    
                    context.opacity = opacity
                    
                    // Draw flame particle as a circle with gradient
                    let rect = CGRect(
                        x: x - particle.size * currentScale / 2,
                        y: y - particle.size * currentScale / 2,
                        width: particle.size * currentScale,
                        height: particle.size * currentScale
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(particle.color))
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
            Color(hex: "ffd700"),  // Yellow
            Color(hex: "ff6b35"),  // Orange
            Color(hex: "ff4444"),  // Red
            Color(hex: "ffaa00"),  // Amber
        ]
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let currentTime = Date().timeIntervalSinceReferenceDate
        
        // Create particles from bottom half of screen
        for _ in 0..<60 {
            let particle = FlameParticle(
                startX: CGFloat.random(in: 0...screenWidth),
                startY: CGFloat.random(in: screenHeight * 0.4...screenHeight),
                riseSpeed: CGFloat.random(in: 80...200),
                wobbleSpeed: Double.random(in: 2...5),
                wobbleAmount: CGFloat.random(in: 10...30),
                size: CGFloat.random(in: 8...20),
                scale: CGFloat.random(in: 0.5...1.0),
                color: colors.randomElement()!,
                maxOpacity: Double.random(in: 0.4...0.8),
                lifetime: Double.random(in: 2...4),
                createdAt: currentTime + Double.random(in: 0...0.5)
            )
            particles.append(particle)
        }
    }
}

struct FlameParticle {
    let startX: CGFloat
    let startY: CGFloat
    let riseSpeed: CGFloat
    let wobbleSpeed: Double
    let wobbleAmount: CGFloat
    let size: CGFloat
    let scale: CGFloat
    let color: Color
    let maxOpacity: Double
    let lifetime: Double
    let createdAt: TimeInterval
}

#Preview {
    StreakCelebrationView(streakCount: 7) {
        print("Dismissed")
    }
}
