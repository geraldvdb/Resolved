//
//  ResolutionDetailView.swift
//  Resolved
//
//  Detailed view for a single resolution showing progress visualization,
//  reward tracking, and recent log entries.
//

import SwiftUI
import SwiftData

/// Detailed view for a single resolution
struct ResolutionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var resolution: Resolution
    
    @State private var showingLogProgress = false
    @State private var showingEditSheet = false
    
    // Celebration state
    @State private var showSuccessToast = false
    @State private var streakToShow: Int? = nil
    @State private var rewardToShow: Reward?
    @State private var pendingRewards: [Reward] = []
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.backgroundGradientStart(colorScheme), AppColors.backgroundGradientEnd(colorScheme)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header card
                    headerCard
                    
                    // Rewards section (if any rewards exist)
                    if !(resolution.rewards ?? []).isEmpty {
                        rewardsSection
                    }
                    
                    // Progress grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress Grid")
                            .font(.custom("Avenir Next", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primaryText(colorScheme))
                        
                        ProgressGrid(
                            totalBlocks: resolution.targetCount,
                            filledBlocks: (resolution.logEntries ?? []).count,
                            logEntries: resolution.logEntries ?? []
                        )
                    }
                    .padding(20)
                    .background(AppColors.cardBackgroundSecondary(colorScheme))
                    .cornerRadius(20)
                    
                    // Recent entries
                    if !(resolution.logEntries ?? []).isEmpty {
                        recentEntriesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            
            // Floating log button
            VStack {
                Spacer()
                Button(action: { showingLogProgress = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Log Progress")
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AppColors.successGradient(colorScheme))
                    .cornerRadius(25)
                    .shadow(color: AppColors.success(colorScheme).opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 24)
            }
            
            // MARK: - Celebration Overlays
            
            // Success toast (shown when no streak)
            if showSuccessToast {
                SuccessToastView(message: "Well done!") {
                    showSuccessToast = false
                    onToastComplete()
                }
                .zIndex(99)
            }
            
            // Streak celebration (shown when streak extended)
            if let streak = streakToShow {
                StreakCelebrationView(streakCount: streak) {
                    streakToShow = nil
                    onStreakDismiss()
                }
                .transition(.opacity)
                .zIndex(100)
            }
            
            // Reward popup overlay
            if let reward = rewardToShow {
                RewardPopupView(reward: reward) {
                    rewardToShow = nil
                    showNextPendingReward()
                }
                .transition(.opacity)
                .zIndex(101)
            }
        }
        .navigationTitle(resolution.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbarBackground(AppColors.background(colorScheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.success(colorScheme))
                }
            }
        }
        .sheet(isPresented: $showingLogProgress) {
            LogProgressSheet(resolution: resolution) { result in
                // Store results
                pendingRewards = result.unlockedRewards
                streakToShow = result.newStreakCount
                
                // Start celebration sequence after sheet dismisses
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startCelebrationSequence()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditResolutionSheet(resolution: resolution)
        }
    }
    
    // MARK: - Celebration Sequence
    
    private func startCelebrationSequence() {
        if let _ = streakToShow {
            // Streak celebration will show (streakToShow is already set)
            // No need to do anything - it's already triggered by the state
        } else {
            // Show simple "Well done!" toast
            showSuccessToast = true
        }
    }
    
    private func onToastComplete() {
        // Toast done, check for rewards
        showNextPendingReward()
    }
    
    private func onStreakDismiss() {
        // Streak done, check for rewards
        showNextPendingReward()
    }
    
    private func showNextPendingReward() {
        guard rewardToShow == nil, !pendingRewards.isEmpty else { return }
        rewardToShow = pendingRewards.removeFirst()
    }
    
    // MARK: - Rewards Section
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rewards")
                    .font(.custom("Avenir Next", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                
                Spacer()
                
                if !resolution.unlockedRewards.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 12))
                        // Show total unlock count (includes multiple unlocks for segment rewards)
                        if resolution.totalUnlockCount > resolution.unlockedRewards.count {
                            Text("\(resolution.totalUnlockCount) unlocked")
                                .font(.custom("Avenir Next", size: 14))
                                .fontWeight(.bold)
                        } else {
                            Text("\(resolution.unlockedRewards.count)/\((resolution.rewards ?? []).count)")
                                .font(.custom("Avenir Next", size: 14))
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(AppColors.gold(colorScheme))
                }
            }
            
            // Next upcoming reward
            if let nextReward = resolution.nextUpcomingReward {
                nextRewardCard(nextReward)
            }
            
            // Reward progress bar
            rewardProgressBar
            
            // Unlocked rewards
            if !resolution.unlockedRewards.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unlocked")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                    
                    ForEach(resolution.unlockedRewards, id: \.id) { reward in
                        unlockedRewardRow(reward)
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.cardBackgroundSecondary(colorScheme))
        .cornerRadius(20)
    }
    
    private func nextRewardCard(_ reward: Reward) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.gold(colorScheme).opacity(AppColors.subtleBackgroundOpacity(colorScheme, base: 0.2)))
                    .frame(width: 50, height: 50)
                
                Image(systemName: reward.triggerIcon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.gold(colorScheme))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Reward")
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundColor(AppColors.secondaryText(colorScheme))
                
                Text(reward.descriptionText)
                    .font(.custom("Avenir Next", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                    .lineLimit(2)
                
                if let target = reward.targetNumber(currentCount: (resolution.logEntries ?? []).count, targetCount: resolution.targetCount) {
                    let remaining = target - (resolution.logEntries ?? []).count
                    Text("\(remaining) more to go")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(AppColors.accent)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppColors.gold(colorScheme).opacity(AppColors.subtleBackgroundOpacity(colorScheme, base: 0.1)), AppColors.accent.opacity(AppColors.subtleBackgroundOpacity(colorScheme, base: 0.1))],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.gold(colorScheme).opacity(AppColors.borderOpacity(colorScheme, base: 0.3)), lineWidth: 1)
        )
    }
    
    private var rewardProgressBar: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let target = max(resolution.targetCount, 1)
            let progress = min(CGFloat((resolution.logEntries ?? []).count) / CGFloat(target), 1.0)
            let progressWidth = max(width * progress, 0)
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.progressTrack(colorScheme))
                    .frame(height: 12)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.accentGradient)
                    .frame(width: progressWidth, height: 12)
                    .animation(.spring(response: 0.5), value: (resolution.logEntries ?? []).count)
                
                // Reward markers
                ForEach(resolution.rewards ?? [], id: \.id) { reward in
                    rewardMarker(for: reward, width: width)
                }
            }
        }
        .frame(height: 28)
    }
    
    private func rewardMarker(for reward: Reward, width: CGFloat) -> some View {
        let targetNumber: Int
        switch reward.triggerType {
        case "segment":
            targetNumber = reward.triggerValue
        case "milestone":
            targetNumber = reward.triggerValue
        case "completion":
            targetNumber = resolution.targetCount
        default:
            targetNumber = resolution.targetCount
        }
        
        let target = max(resolution.targetCount, 1)
        let position = min(width * CGFloat(targetNumber) / CGFloat(target), width)
        
        return ZStack {
            if reward.isUnlocked {
                Circle()
                    .fill(AppColors.gold(colorScheme).opacity(AppColors.borderOpacity(colorScheme, base: 0.3)))
                    .frame(width: 28, height: 28)
            }
            
            Circle()
                .fill(reward.isUnlocked ? AppColors.gold(colorScheme) : AppColors.progressTrack(colorScheme))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(reward.isUnlocked ? AppColors.gold(colorScheme) : AppColors.secondaryText(colorScheme).opacity(0.5), lineWidth: 2)
                )
            
            Image(systemName: reward.isUnlocked ? "checkmark" : reward.triggerIcon)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(reward.isUnlocked ? AppColors.background(colorScheme) : AppColors.secondaryText(colorScheme))
        }
        .offset(x: position - 10, y: 0)
    }
    
    private func unlockedRewardRow(_ reward: Reward) -> some View {
        let currentCount = (resolution.logEntries ?? []).count
        let displayCount = reward.triggerType == "segment" 
            ? reward.expectedUnlockCount(currentCount: currentCount)
            : reward.unlockCount
        
        return HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppColors.success(colorScheme))
            
            Text(reward.descriptionText)
                .font(.custom("Avenir Next", size: 14))
                .foregroundColor(AppColors.primaryText(colorScheme))
                .lineLimit(1)
            
            // Show unlock count for segment rewards
            if reward.triggerType == "segment" && displayCount > 1 {
                Text("×\(displayCount)")
                    .font(.custom("Avenir Next", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.gold(colorScheme))
            }
            
            Spacer()
            
            Text(reward.triggerDisplayName)
                .font(.custom("Avenir Next", size: 12))
                .foregroundColor(AppColors.secondaryText(colorScheme))
        }
        .padding(12)
        .background(AppColors.background(colorScheme))
        .cornerRadius(10)
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(AppColors.cardBackground(colorScheme), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(resolution.progressPercentage / 100))
                    .stroke(
                        AppColors.accentGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: resolution.progressPercentage)
                
                VStack(spacing: 2) {
                    Text("\(Int(resolution.progressPercentage))%")
                        .font(.custom("Avenir Next", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText(colorScheme))
                    
                    Text(resolution.progressFraction)
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                }
            }
            
            // Description
            if !resolution.descriptionText.isEmpty {
                Text(resolution.descriptionText)
                    .font(.custom("Avenir Next", size: 16))
                    .foregroundColor(AppColors.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Stats row
            HStack(spacing: 40) {
                statItem(value: "\((resolution.logEntries ?? []).count)", label: "Logged")
                statItem(value: "\(resolution.targetCount - (resolution.logEntries ?? []).count)", label: "Remaining")
                if !(resolution.rewards ?? []).isEmpty {
                    statItem(value: "\(resolution.unlockedRewards.count)", label: "Rewards")
                }
            }
        }
        .padding(24)
        .background(AppColors.cardBackgroundSecondary(colorScheme))
        .cornerRadius(20)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Avenir Next", size: 24))
                .fontWeight(.bold)
                .foregroundColor(AppColors.accent)
            Text(label)
                .font(.custom("Avenir Next", size: 14))
                .foregroundColor(AppColors.secondaryText(colorScheme))
        }
    }
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Entries")
                .font(.custom("Avenir Next", size: 18))
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText(colorScheme))
            
            let sortedEntries = (resolution.logEntries ?? []).sorted { $0.date > $1.date }
            ForEach(sortedEntries.prefix(5)) { entry in
                logEntryRow(entry: entry)
            }
        }
        .padding(20)
        .background(AppColors.cardBackgroundSecondary(colorScheme))
        .cornerRadius(20)
    }
    
    private func logEntryRow(entry: LogEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.custom("Avenir Next", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primaryText(colorScheme))
                
                if !entry.descriptionText.isEmpty {
                    Text(entry.descriptionText)
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(AppColors.secondaryText(colorScheme))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.success(colorScheme))
        }
        .padding(16)
        .background(AppColors.background(colorScheme))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ResolutionDetailView(resolution: Resolution(name: "Go to the gym", descriptionText: "Get fit and healthy this year!", targetCount: 100))
    }
    .modelContainer(for: [Resolution.self, LogEntry.self, Reward.self], inMemory: true)
}
