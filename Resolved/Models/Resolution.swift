import Foundation
import SwiftData

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
    
    var progressPercentage: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double((logEntries ?? []).count) / Double(targetCount) * 100, 100)
    }
    
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
    
    /// Returns rewards that are still pending
    var pendingRewards: [Reward] {
        (rewards ?? []).filter { !$0.isUnlocked }
    }
    
    /// Check and unlock rewards when progress changes
    /// Returns array of newly unlocked rewards
    @discardableResult
    func checkAndUnlockRewards(previousCount: Int) -> [Reward] {
        let currentCount = (logEntries ?? []).count
        var newlyUnlocked: [Reward] = []
        
        for reward in (rewards ?? []) {
            if reward.shouldTrigger(at: currentCount, previousCount: previousCount, targetCount: targetCount) {
                reward.unlock()
                newlyUnlocked.append(reward)
            }
        }
        
        return newlyUnlocked
    }
    
    /// Find the next upcoming reward based on current progress
    var nextUpcomingReward: Reward? {
        let currentCount = (logEntries ?? []).count
        
        return pendingRewards
            .compactMap { reward -> (Reward, Int)? in
                guard let target = reward.targetNumber(currentCount: currentCount, targetCount: targetCount) else {
                    return nil
                }
                return (reward, target)
            }
            .filter { $0.1 > currentCount }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }
    
    /// Add a reward to this resolution
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
    
    /// Current streak - consecutive days with at least one log entry
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
    
    /// Number of logs needed until next reward (nil if no pending rewards)
    var logsUntilNextReward: Int? {
        let currentCount = (logEntries ?? []).count
        guard let next = nextUpcomingReward,
              let target = next.targetNumber(currentCount: currentCount, targetCount: targetCount) else { return nil }
        return max(0, target - currentCount)
    }
}
