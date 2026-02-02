//
//  HomeView.swift
//  Resolved
//
//  Main view displaying all resolutions with progress summaries.
//  Provides access to add new resolutions and log progress.
//

import SwiftUI
import SwiftData

/// The main home screen showing all user resolutions
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Resolution.createdDate, order: .reverse) private var resolutions: [Resolution]
    
    @State private var showingAddResolution = false
    @State private var resolutionToLog: Resolution?
    
    // Celebration state
    @State private var showSuccessToast = false
    @State private var streakToShow: Int? = nil
    @State private var rewardToShow: Reward?
    @State private var pendingRewards: [Reward] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [AppColors.backgroundGradientStart(colorScheme), AppColors.backgroundGradientEnd(colorScheme)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if resolutions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // App header with logo
                            HStack(spacing: 12) {
                                // Mountain logo
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [AppColors.accent.opacity(0.2), AppColors.accentLight.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "mountain.2.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(AppColors.accentGradient)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Resolved")
                                        .font(.custom("Avenir Next", size: 28))
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.primaryText(colorScheme))
                                    
                                    Text("Track your goals")
                                        .font(.custom("Avenir Next", size: 13))
                                        .foregroundColor(AppColors.secondaryText(colorScheme))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            
                            // Resolution cards
                            LazyVStack(spacing: 16) {
                                ForEach(resolutions) { resolution in
                                NavigationLink(destination: ResolutionDetailView(resolution: resolution)) {
                                    ResolutionCard(
                                        resolution: resolution,
                                        onLogTapped: {
                                            resolutionToLog = resolution
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddResolution = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(AppColors.background(colorScheme))
                                    .frame(width: 64, height: 64)
                                    .background(AppColors.successGradient(colorScheme))
                                    .clipShape(Circle())
                                    .shadow(color: AppColors.successDark(colorScheme).opacity(0.5), radius: 12, x: 0, y: 6)
                                
                                Text("New Goal")
                                    .font(.custom("Avenir Next", size: 11))
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.primaryText(colorScheme).opacity(0.8))
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 20)
                    }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddResolution) {
                AddResolutionSheet()
            }
            .sheet(item: $resolutionToLog) { resolution in
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
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundColor(AppColors.accent)
            
            Text("No Resolutions Yet")
                .font(.custom("Avenir Next", size: 24))
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText(colorScheme))
            
            Text("Tap the + button to add your first resolution")
                .font(.custom("Avenir Next", size: 16))
                .foregroundColor(AppColors.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Resolution.self, LogEntry.self, Reward.self], inMemory: true)
}
