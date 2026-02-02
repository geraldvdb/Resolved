//
//  ResolvedTests.swift
//  ResolvedTests
//
//  Unit tests for the Resolved habit tracking app.
//  Tests core model logic including rewards, streaks, and progress tracking.
//

import Testing
import Foundation
@testable import Resolved

// MARK: - Reward Trigger Tests

struct RewardTriggerTests {
    
    // MARK: Segment Rewards
    
    @Test func segmentRewardTriggersAtInterval() {
        let reward = Reward(descriptionText: "Coffee!", triggerType: "segment", triggerValue: 10)
        
        // Should trigger at 10
        #expect(reward.shouldTrigger(at: 10, previousCount: 9, targetCount: 100))
        
        // Should trigger at 20
        #expect(reward.shouldTrigger(at: 20, previousCount: 19, targetCount: 100))
        
        // Should NOT trigger at 15
        #expect(!reward.shouldTrigger(at: 15, previousCount: 14, targetCount: 100))
    }
    
    @Test func segmentRewardCountsMultipleCrossings() {
        let reward = Reward(descriptionText: "Coffee!", triggerType: "segment", triggerValue: 10)
        
        // Crossing from 5 to 25 crosses 2 segment boundaries (10 and 20)
        let count = reward.newUnlockCount(at: 25, previousCount: 5)
        #expect(count == 2)
        
        // Crossing from 15 to 35 crosses 2 segment boundaries (20 and 30)
        let count2 = reward.newUnlockCount(at: 35, previousCount: 15)
        #expect(count2 == 2)
    }
    
    @Test func segmentRewardCanTriggerAfterUnlock() {
        let reward = Reward(descriptionText: "Coffee!", triggerType: "segment", triggerValue: 10)
        
        // Trigger at 10
        #expect(reward.shouldTrigger(at: 10, previousCount: 9, targetCount: 100))
        reward.unlock()
        
        // Should still trigger at 20 (segment rewards can repeat)
        #expect(reward.shouldTrigger(at: 20, previousCount: 19, targetCount: 100))
    }
    
    @Test func segmentRewardWithZeroValueDoesNotTrigger() {
        let reward = Reward(descriptionText: "Invalid", triggerType: "segment", triggerValue: 0)
        #expect(!reward.shouldTrigger(at: 10, previousCount: 9, targetCount: 100))
    }
    
    // MARK: Milestone Rewards
    
    @Test func milestoneRewardTriggersOnce() {
        let reward = Reward(descriptionText: "Halfway!", triggerType: "milestone", triggerValue: 50)
        
        // Should trigger when reaching milestone
        #expect(reward.shouldTrigger(at: 50, previousCount: 49, targetCount: 100))
        
        // Mark as unlocked
        reward.unlock()
        
        // Should NOT trigger again
        #expect(!reward.shouldTrigger(at: 51, previousCount: 50, targetCount: 100))
    }
    
    @Test func milestoneRewardTriggersWhenExceeding() {
        let reward = Reward(descriptionText: "Quarter!", triggerType: "milestone", triggerValue: 25)
        
        // Should trigger when jumping past milestone
        #expect(reward.shouldTrigger(at: 30, previousCount: 20, targetCount: 100))
    }
    
    // MARK: Completion Rewards
    
    @Test func completionRewardTriggersAtTarget() {
        let reward = Reward(descriptionText: "Complete!", triggerType: "completion", triggerValue: 0)
        
        // Should trigger when reaching target
        #expect(reward.shouldTrigger(at: 100, previousCount: 99, targetCount: 100))
        
        // Mark as unlocked
        reward.unlock()
        
        // Should NOT trigger again
        #expect(!reward.shouldTrigger(at: 101, previousCount: 100, targetCount: 100))
    }
    
    @Test func completionRewardDoesNotTriggerEarly() {
        let reward = Reward(descriptionText: "Complete!", triggerType: "completion", triggerValue: 0)
        
        #expect(!reward.shouldTrigger(at: 99, previousCount: 98, targetCount: 100))
    }
    
    // MARK: Unlock Behavior
    
    @Test func unlockSetsCorrectProperties() {
        let reward = Reward(descriptionText: "Test", triggerType: "milestone", triggerValue: 10)
        
        #expect(!reward.isUnlocked)
        #expect(reward.unlockCount == 0)
        #expect(reward.unlockedAt == nil)
        
        reward.unlock()
        
        #expect(reward.isUnlocked)
        #expect(reward.unlockCount == 1)
        #expect(reward.unlockedAt != nil)
    }
    
    @Test func segmentUnlockIncrementsCount() {
        let reward = Reward(descriptionText: "Coffee!", triggerType: "segment", triggerValue: 10)
        
        reward.unlock(incrementBy: 2)
        #expect(reward.unlockCount == 2)
        
        reward.unlock(incrementBy: 3)
        #expect(reward.unlockCount == 5)
    }
}

// MARK: - Reward Display Tests

struct RewardDisplayTests {
    
    @Test func triggerDisplayNameFormatsCorrectly() {
        let segment = Reward(descriptionText: "A", triggerType: "segment", triggerValue: 10)
        #expect(segment.triggerDisplayName == "Every 10")
        
        let milestone = Reward(descriptionText: "B", triggerType: "milestone", triggerValue: 25)
        #expect(milestone.triggerDisplayName == "At #25")
        
        let completion = Reward(descriptionText: "C", triggerType: "completion", triggerValue: 0)
        #expect(completion.triggerDisplayName == "Full Completion")
    }
    
    @Test func targetNumberCalculatesCorrectly() {
        let segment = Reward(descriptionText: "A", triggerType: "segment", triggerValue: 10)
        #expect(segment.targetNumber(currentCount: 5, targetCount: 100) == 10)
        #expect(segment.targetNumber(currentCount: 15, targetCount: 100) == 20)
        #expect(segment.targetNumber(currentCount: 20, targetCount: 100) == 30)
        
        let milestone = Reward(descriptionText: "B", triggerType: "milestone", triggerValue: 25)
        #expect(milestone.targetNumber(currentCount: 5, targetCount: 100) == 25)
        
        let completion = Reward(descriptionText: "C", triggerType: "completion", triggerValue: 0)
        #expect(completion.targetNumber(currentCount: 50, targetCount: 100) == 100)
    }
}

// MARK: - Resolution Tests

struct ResolutionTests {
    
    @Test func progressPercentageCalculatesCorrectly() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        #expect(resolution.progressPercentage == 0)
        
        // Add entries by creating and assigning individual entries
        let entry1 = LogEntry(date: Date(), descriptionText: "")
        let entry2 = LogEntry(date: Date(), descriptionText: "")
        resolution.logEntries = [entry1, entry2]
        #expect(resolution.progressPercentage == 2)
    }
    
    @Test func progressPercentageCapsAt100() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 10)
        // Create 15 unique entries (not using Array(repeating:) which creates references to same object)
        var entries: [LogEntry] = []
        for _ in 0..<15 {
            entries.append(LogEntry(date: Date(), descriptionText: ""))
        }
        resolution.logEntries = entries
        #expect(resolution.progressPercentage == 100)
    }
    
    @Test func progressFractionFormatsCorrectly() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        // Create 25 unique entries
        var entries: [LogEntry] = []
        for _ in 0..<25 {
            entries.append(LogEntry(date: Date(), descriptionText: ""))
        }
        resolution.logEntries = entries
        #expect(resolution.progressFraction == "25/100")
    }
    
    @Test func unlockedRewardsFiltersCorrectly() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        
        let unlocked = Reward(descriptionText: "Unlocked", triggerType: "milestone", triggerValue: 10, isUnlocked: true)
        let pending = Reward(descriptionText: "Pending", triggerType: "milestone", triggerValue: 50, isUnlocked: false)
        
        resolution.rewards = [unlocked, pending]
        
        #expect(resolution.unlockedRewards.count == 1)
        #expect(resolution.unlockedRewards.first?.descriptionText == "Unlocked")
        
        #expect(resolution.pendingRewards.count == 1)
        #expect(resolution.pendingRewards.first?.descriptionText == "Pending")
    }
}

// MARK: - Streak Calculation Tests

struct StreakTests {
    
    @Test func emptyEntriesHasNoStreak() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        resolution.logEntries = []
        #expect(resolution.currentStreak == 0)
    }
    
    @Test func singleTodayEntryHasStreakOfOne() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        resolution.logEntries = [LogEntry(date: Date(), descriptionText: "")]
        #expect(resolution.currentStreak == 1)
    }
    
    @Test func consecutiveDaysCountCorrectly() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        let calendar = Calendar.current
        let today = Date()
        
        resolution.logEntries = [
            LogEntry(date: today, descriptionText: ""),
            LogEntry(date: calendar.date(byAdding: .day, value: -1, to: today)!, descriptionText: ""),
            LogEntry(date: calendar.date(byAdding: .day, value: -2, to: today)!, descriptionText: "")
        ]
        
        #expect(resolution.currentStreak == 3)
    }
    
    @Test func gapBreaksStreak() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        let calendar = Calendar.current
        let today = Date()
        
        // Today and 3 days ago (gap of 2 days)
        resolution.logEntries = [
            LogEntry(date: today, descriptionText: ""),
            LogEntry(date: calendar.date(byAdding: .day, value: -3, to: today)!, descriptionText: "")
        ]
        
        // Only today counts since there's a gap
        #expect(resolution.currentStreak == 1)
    }
    
    @Test func streakStartsFromYesterdayIfNoLogToday() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        let calendar = Calendar.current
        let today = Date()
        
        // Yesterday and day before only (no log today)
        resolution.logEntries = [
            LogEntry(date: calendar.date(byAdding: .day, value: -1, to: today)!, descriptionText: ""),
            LogEntry(date: calendar.date(byAdding: .day, value: -2, to: today)!, descriptionText: "")
        ]
        
        #expect(resolution.currentStreak == 2)
    }
    
    @Test func multipleEntriesSameDayCountAsOne() {
        let resolution = Resolution(name: "Test", descriptionText: "", targetCount: 100)
        let today = Date()
        
        // Multiple entries today
        resolution.logEntries = [
            LogEntry(date: today, descriptionText: "Morning"),
            LogEntry(date: today, descriptionText: "Evening"),
            LogEntry(date: today, descriptionText: "Night")
        ]
        
        #expect(resolution.currentStreak == 1)
    }
}

// MARK: - Log Entry Tests

struct LogEntryTests {
    
    @Test func initializesWithDefaults() {
        let entry = LogEntry()
        
        #expect(entry.id != UUID())  // Should have a unique ID
        #expect(entry.descriptionText == "")
        // Date should be approximately now
        #expect(abs(entry.date.timeIntervalSinceNow) < 1)
    }
    
    @Test func initializesWithCustomValues() {
        let customDate = Date(timeIntervalSince1970: 0)
        let entry = LogEntry(date: customDate, descriptionText: "Test note")
        
        #expect(entry.date == customDate)
        #expect(entry.descriptionText == "Test note")
    }
}
