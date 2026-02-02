//
//  LogProgressSheet.swift
//  Resolved
//
//  Sheet for logging progress on a resolution. Includes date picker,
//  optional notes, and handles reward unlocking and streak detection.
//

import SwiftUI
import SwiftData

/// Result returned when progress is logged, containing unlocked rewards and streak info
struct LogResult {
    let unlockedRewards: [Reward]
    let newStreakCount: Int?  // nil if streak not extended, otherwise the new streak count
}

struct LogProgressSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let resolution: Resolution
    var onLogComplete: ((LogResult) -> Void)?
    
    @State private var date = Date()
    @State private var descriptionText = ""
    
    @FocusState private var isDescriptionFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 24) {
                                // Resolution name header
                                VStack(spacing: 4) {
                                    Text("Logging progress for")
                                        .font(.custom("Avenir Next", size: 14))
                                        .foregroundColor(AppColors.secondaryText(colorScheme))
                                    Text(resolution.name)
                                        .font(.custom("Avenir Next", size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.primaryText(colorScheme))
                                }
                                .padding(.top, 8)
                                
                                // Next reward hint
                                if let nextReward = resolution.nextUpcomingReward,
                                   let target = nextReward.targetNumber(currentCount: (resolution.logEntries ?? []).count, targetCount: resolution.targetCount) {
                                    let remaining = target - (resolution.logEntries ?? []).count
                                    if remaining <= 5 && remaining > 0 {
                                        HStack {
                                            Image(systemName: "gift.fill")
                                                .foregroundColor(AppColors.gold(colorScheme))
                                            Text("\(remaining) more to unlock: \(nextReward.descriptionText)")
                                                .font(.custom("Avenir Next", size: 14))
                                                .foregroundColor(AppColors.gold(colorScheme))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(AppColors.gold(colorScheme).opacity(AppColors.subtleBackgroundOpacity(colorScheme, base: 0.15)))
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // Date picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Date")
                                        .font(.custom("Avenir Next", size: 14))
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.secondaryText(colorScheme))
                                    
                                    DatePicker(
                                        "",
                                        selection: $date,
                                        in: ...Date(),
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(.graphical)
                                    .tint(AppColors.accent)
                                    .colorScheme(colorScheme)
                                    .padding()
                                    .background(AppColors.cardBackground(colorScheme))
                                    .cornerRadius(16)
                                }
                                
                                // Description field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes (optional)")
                                        .font(.custom("Avenir Next", size: 14))
                                        .fontWeight(.medium)
                                        .foregroundColor(AppColors.secondaryText(colorScheme))
                                    
                                    TextField("", text: $descriptionText, prompt: Text("Any details you want to record?").foregroundColor(AppColors.secondaryText(colorScheme).opacity(0.6)))
                                        .font(.custom("Avenir Next", size: 16))
                                        .foregroundColor(AppColors.primaryText(colorScheme))
                                        .padding()
                                        .background(AppColors.inputBackground(colorScheme))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.accent.opacity(isDescriptionFocused ? 1 : 0), lineWidth: 2)
                                        )
                                        .focused($isDescriptionFocused)
                                        .submitLabel(.done)
                                        .onSubmit { isDescriptionFocused = false }
                                        .id("notesField")
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                        }
                        .onChange(of: isDescriptionFocused) { _, focused in
                            if focused {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo("notesField", anchor: UnitPoint(x: 0.5, y: 0.7))
                                    }
                                }
                            }
                        }
                    }
                    
                    // Fixed Log button at bottom
                    VStack {
                        Button(action: logProgress) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Log")
                                    .font(.custom("Avenir Next", size: 18))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.successGradient(colorScheme))
                            .cornerRadius(16)
                            .shadow(color: AppColors.success(colorScheme).opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                    .background(
                        AppColors.background(colorScheme)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
                    )
                }
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbarBackground(AppColors.background(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private func logProgress() {
        // Capture previous state
        let previousCount = (resolution.logEntries ?? []).count
        let previousStreak = resolution.currentStreak
        
        // Create and add the log entry
        let entry = LogEntry(date: date, descriptionText: descriptionText)
        entry.resolution = resolution
        if resolution.logEntries == nil {
            resolution.logEntries = []
        }
        resolution.logEntries?.append(entry)
        modelContext.insert(entry)
        
        // Check for newly unlocked rewards
        let newlyUnlocked = resolution.checkAndUnlockRewards(previousCount: previousCount)
        
        // Check if streak was extended
        let newStreak = resolution.currentStreak
        let streakExtended = newStreak > previousStreak && newStreak > 1
        
        // Create result and notify parent
        let result = LogResult(
            unlockedRewards: newlyUnlocked,
            newStreakCount: streakExtended ? newStreak : nil
        )
        onLogComplete?(result)
        
        dismiss()
    }
}

#Preview {
    LogProgressSheet(resolution: Resolution(name: "Go to the gym", descriptionText: "Get fit!", targetCount: 100))
        .modelContainer(for: [Resolution.self, LogEntry.self, Reward.self], inMemory: true)
}
