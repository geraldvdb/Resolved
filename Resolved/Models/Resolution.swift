//
//  Resolution.swift
//  Resolved
//
//  SwiftData model representing a user's resolution or goal to track.
//  Resolutions have a target count and can be associated with log entries
//  and rewards that unlock at various milestones.
//

import Foundation
import SwiftData

/// A resolution or goal that the user wants to track progress toward.
///
/// Resolutions are the core entity in the app. Each resolution has:
/// - A name and optional description
/// - A target count (e.g., "100 gym visits")
/// - Associated log entries tracking each completion
/// - Optional rewards that unlock at milestones
@Model
final class Resolution {
    // CloudKit requires default values for all stored properties
    var id: UUID = UUID()
    var name: String = ""
    var descriptionText: String = ""
    var targetCount: Int = 100
    var createdDate: Date = Date()
    
    // CloudKit requires relationships to be optional
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.resolution)
    var logEntries: [LogEntry]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \Reward.resolution)
    var rewards: [Reward]? = []
    
    /// Progress as a percentage (0-100)
    var progressPercentage: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double((logEntries ?? []).count) / Double(targetCount) * 100, 100)
    }
    
    /// Progress as a fraction string (e.g., "25/100")
    var progressFraction: String {
        "\((logEntries ?? []).count)/\(targetCount)"
    }
    
    init(name: String, descriptionText: String, targetCount: Int) {
        self.id = UUID()
        self.name = name
        self.descriptionText = descriptionText
        self.targetCount = targetCount
        self.createdDate = Date()
    }
    
    // MARK: - Reward Helpers
    
    /// Returns rewards that have been unlocked
    var unlockedRewards: [Reward] {
        (rewards ?? []).filter { $0.isUnlocked }
    }
    
    /// Returns rewards that are still pending (not yet unlocked)
    var pendingRewards: [Reward] {
        (rewards ?? []).filter { !$0.isUnlocked }
    }
    
    /// Total number of times rewards have been unlocked.
    /// Counts segment rewards multiple times (e.g., "every 10" counts each milestone).
    /// Uses the expected count based on actual progress to ensure accuracy even if
    /// entries were added without going through normal reward tracking.
    var totalUnlockCount: Int {
        let currentCount = (logEntries ?? []).count
        return (rewards ?? []).reduce(0) { total, reward in
            if reward.triggerType == "segment" {
                // Use the expected count based on actual progress
                return total + reward.expectedUnlockCount(currentCount: currentCount)
            } else {
                return total + reward.unlockCount
            }
        }
    }
    
    /// Checks all rewards and unlocks any that should trigger based on the progress change.
    /// Also syncs segment reward unlock counts to match actual progress.
    /// - Parameter previousCount: The log entry count before the latest entry was added
    /// - Returns: Array of newly unlocked rewards (segment rewards may appear multiple times)
    @discardableResult
    func checkAndUnlockRewards(previousCount: Int) -> [Reward] {
        let currentCount = (logEntries ?? []).count
        var newlyUnlocked: [Reward] = []
        
        for reward in (rewards ?? []) {
            if reward.shouldTrigger(at: currentCount, previousCount: previousCount, targetCount: targetCount) {
                let newUnlocks = reward.newUnlockCount(at: currentCount, previousCount: previousCount)
                reward.unlock(incrementBy: newUnlocks)
                // Add to array once per new unlock (for animation purposes)
                for _ in 0..<newUnlocks {
                    newlyUnlocked.append(reward)
                }
            }
            
            // Sync segment reward unlock counts to match actual progress
            // This fixes cases where entries were added without proper reward tracking
            if reward.triggerType == "segment" && reward.isUnlocked {
                let expectedCount = reward.expectedUnlockCount(currentCount: currentCount)
                if reward.unlockCount < expectedCount {
                    reward.unlockCount = expectedCount
                }
            }
        }
        
        return newlyUnlocked
    }
    
    /// Finds the next reward that will unlock based on current progress.
    /// For segment rewards, this returns the next segment milestone.
    var nextUpcomingReward: Reward? {
        let currentCount = (logEntries ?? []).count
        
        // Include segment rewards (they repeat) and pending one-time rewards
        let eligibleRewards = (rewards ?? []).filter { reward in
            reward.triggerType == "segment" || !reward.isUnlocked
        }
        
        return eligibleRewards
            .compactMap { reward -> (Reward, Int)? in
                guard let target = reward.targetNumber(currentCount: currentCount, targetCount: targetCount) else {
                    return nil
                }
                // For segment rewards, only show if next target is within overall target
                if reward.triggerType == "segment" && target > targetCount {
                    return nil
                }
                return (reward, target)
            }
            .filter { $0.1 > currentCount }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }
    
    /// Adds a reward to this resolution
    /// - Parameter reward: The reward to add
    func addReward(_ reward: Reward) {
        reward.resolution = self
        if rewards == nil {
            rewards = []
        }
        rewards?.append(reward)
    }
    
    // MARK: - Stats Properties
    
    /// Count of log entries from the current calendar week
    var thisWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        return (logEntries ?? []).filter { $0.date >= weekStart }.count
    }
    
    /// Current streak - consecutive days with at least one log entry.
    /// Counts backwards from today (or yesterday if no log today).
    var currentStreak: Int {
        let entries = logEntries ?? []
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get unique days with log entries, sorted descending
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)
        
        guard !uniqueDays.isEmpty else { return 0 }
        
        var streak = 0
        var expectedDay = today
        
        // If no log today, start from yesterday
        if !uniqueDays.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            expectedDay = yesterday
        }
        
        for day in uniqueDays {
            if day == expectedDay {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDay) else { break }
                expectedDay = previousDay
            } else if day < expectedDay {
                // Gap in streak
                break
            }
        }
        
        return streak
    }
    
    /// Number of logs needed until next reward (nil if no upcoming rewards)
    var logsUntilNextReward: Int? {
        let currentCount = (logEntries ?? []).count
        guard let next = nextUpcomingReward,
              let target = next.targetNumber(currentCount: currentCount, targetCount: targetCount) else { return nil }
        return max(0, target - currentCount)
    }
}
