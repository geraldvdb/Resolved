import SwiftUI

struct ResolutionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let resolution: Resolution
    let onLogTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(resolution.name)
                        .font(.custom("Avenir Next", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText(colorScheme))
                    
                    if !resolution.descriptionText.isEmpty {
                        Text(resolution.descriptionText)
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundColor(AppColors.secondaryText(colorScheme))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Progress percentage circle
                ZStack {
                    Circle()
                        .stroke(AppColors.progressTrack(colorScheme), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(resolution.progressPercentage / 100))
                        .stroke(
                            AppColors.accentGradient,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(resolution.progressPercentage))%")
                        .font(.custom("Avenir Next", size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText(colorScheme))
                }
            }
            
            // Stats row
            HStack(spacing: 0) {
                // This Week
                statItem(
                    icon: "calendar",
                    label: "This Week",
                    value: "\(resolution.thisWeekCount)"
                )
                
                Spacer()
                
                // Streak
                statItem(
                    icon: "flame.fill",
                    label: "Streak",
                    value: resolution.currentStreak > 0 ? "\(resolution.currentStreak) day\(resolution.currentStreak == 1 ? "" : "s")" : "—"
                )
                
                Spacer()
                
                // Next Reward
                if let logsNeeded = resolution.logsUntilNextReward {
                    statItem(
                        icon: "gift.fill",
                        label: "Next Reward",
                        value: logsNeeded > 0 ? "\(logsNeeded) to go" : "Ready!"
                    )
                } else {
                    statItem(
                        icon: "gift.fill",
                        label: "Next Reward",
                        value: "—"
                    )
                }
            }
            .padding(.vertical, 8)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    let width = max(geometry.size.width, 1)
                    let progress = min(max(resolution.progressPercentage, 0), 100)
                    let progressWidth = max(width * CGFloat(progress / 100), 0)
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.progressTrack(colorScheme))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.accentGradient)
                            .frame(width: progressWidth, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: resolution.progressPercentage)
                    }
                }
                .frame(height: 8)
                
                // Progress text and Log button
                HStack {
                    Text(resolution.progressFraction)
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                    
                    Spacer()
                    
                    // Quick Log button
                    Button(action: onLogTapped) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Log Progress")
                                .font(.custom("Avenir Next", size: 12))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.successGradient)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                        .padding(.leading, 8)
                }
            }
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.border(colorScheme), lineWidth: 1)
        )
        .shadow(color: AppColors.cardShadow(colorScheme), radius: 12, x: 0, y: 6)
    }
    
    private var cardBackground: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [Color(hex: "243352"), Color(hex: "1e2a45")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color.white, Color(hex: "f8f8fa")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    private func statItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.accent)
                Text(label)
                    .font(.custom("Avenir Next", size: 10))
                    .foregroundColor(AppColors.secondaryText(colorScheme))
            }
            Text(value)
                .font(.custom("Avenir Next", size: 14))
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText(colorScheme))
        }
    }
}

#Preview {
    ZStack {
        AppColors.background(.dark).ignoresSafeArea()
        ResolutionCard(
            resolution: Resolution(name: "Go to the gym", descriptionText: "Get healthy and fit this year", targetCount: 100),
            onLogTapped: {}
        )
        .padding()
    }
}
