//
//  Reward.swift
//  Resolved
//
//  SwiftData model for rewards that can be unlocked at milestones.
//  Supports three trigger types: segment (repeating), milestone (one-time), and completion.
//

import Foundation
import SwiftData

/// A reward that unlocks when the user reaches certain progress milestones.
///
/// Rewards provide motivation by giving users something to look forward to.
/// Three trigger types are supported:
/// - **Segment**: Repeats every N entries (e.g., "every 10")
/// - **Milestone**: Triggers once at a specific count (e.g., "at #25")
/// - **Completion**: Triggers when the resolution target is fully achieved
@Model
final class Reward {
    // CloudKit requires default values for all stored properties
    var id: UUID = UUID()
    var descriptionText: String = ""
    var triggerType: String = "milestone"  // "segment", "milestone", "completion"
    var triggerValue: Int = 0              // e.g., 10 for every 10, 25 for at #25, 0 for completion
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var unlockCount: Int = 0               // For segment rewards: tracks how many times unlocked
    var resolution: Resolution?
    
    init(
        descriptionText: String,
        triggerType: String,
        triggerValue: Int,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        unlockCount: Int = 0
    ) {
        self.id = UUID()
        self.descriptionText = descriptionText
        self.triggerType = triggerType
        self.triggerValue = triggerValue
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.unlockCount = unlockCount
    }
    
    // MARK: - Display Properties
    
    /// Human-readable description of when this reward triggers
    var triggerDisplayName: String {
        switch triggerType {
        case "segment":
            return "Every \(triggerValue)"
        case "milestone":
            return "At #\(triggerValue)"
        case "completion":
            return "Full Completion"
        default:
            return triggerType
        }
    }
    
    /// SF Symbol icon name appropriate for this trigger type
    var triggerIcon: String {
        switch triggerType {
        case "segment":
            return "repeat.circle.fill"
        case "milestone":
            return "flag.fill"
        case "completion":
            return "trophy.fill"
        default:
            return "gift.fill"
        }
    }
    
    // MARK: - Trigger Logic
    
    /// Determines if this reward should trigger based on progress change.
    ///
    /// For segment rewards, this can return true multiple times (at 10, 20, 30, etc.)
    /// For milestone and completion rewards, this only returns true once.
    ///
    /// - Parameters:
    ///   - count: Current log entry count
    ///   - previousCount: Count before the latest entry
    ///   - targetCount: The resolution's target count (used for completion triggers)
    /// - Returns: True if the reward should trigger
    func shouldTrigger(at count: Int, previousCount: Int, targetCount: Int) -> Bool {
        switch triggerType {
        case "segment":
            // Segment rewards can trigger multiple times
            guard triggerValue > 0 else { return false }
            let previousSegments = previousCount / triggerValue
            let currentSegments = count / triggerValue
            return currentSegments > previousSegments
            
        case "milestone":
            // Milestone rewards only trigger once
            guard !isUnlocked else { return false }
            return count >= triggerValue && previousCount < triggerValue
            
        case "completion":
            // Completion rewards only trigger once
            guard !isUnlocked else { return false }
            return count >= targetCount && previousCount < targetCount
            
        default:
            return false
        }
    }
    
    /// Calculates how many segment boundaries were crossed.
    /// Used when a user logs multiple entries at once.
    ///
    /// - Parameters:
    ///   - count: Current log entry count
    ///   - previousCount: Count before the entries were added
    /// - Returns: Number of new unlocks (always 1 for non-segment rewards)
    func newUnlockCount(at count: Int, previousCount: Int) -> Int {
        guard triggerType == "segment", triggerValue > 0 else { return 1 }
        let previousSegments = previousCount / triggerValue
        let currentSegments = count / triggerValue
        return max(0, currentSegments - previousSegments)
    }
    
    /// Marks this reward as unlocked.
    ///
    /// For segment rewards, increments the unlock count.
    /// For other rewards, sets the count to 1.
    ///
    /// - Parameter incrementBy: Number of unlocks to add (for segment rewards)
    func unlock(incrementBy: Int = 1) {
        isUnlocked = true
        unlockedAt = Date()
        if triggerType == "segment" {
            unlockCount += incrementBy
        } else {
            unlockCount = 1
        }
    }
    
    /// Calculates the expected unlock count based on current progress.
    /// This is used for segment rewards to ensure the displayed count matches actual progress,
    /// even if entries were added without going through the normal reward tracking flow.
    ///
    /// - Parameter currentCount: Current number of log entries
    /// - Returns: Expected number of times this reward should have been unlocked
    func expectedUnlockCount(currentCount: Int) -> Int {
        guard triggerType == "segment", triggerValue > 0 else {
            return isUnlocked ? 1 : 0
        }
        return currentCount / triggerValue
    }
    
    /// Gets the next target number for progress display.
    ///
    /// - Parameters:
    ///   - currentCount: Current log entry count
    ///   - targetCount: The resolution's target count
    /// - Returns: The next milestone number, or nil if not applicable
    func targetNumber(currentCount: Int, targetCount: Int) -> Int? {
        switch triggerType {
        case "segment":
            guard triggerValue > 0 else { return nil }
            return ((currentCount / triggerValue) + 1) * triggerValue
            
        case "milestone":
            return triggerValue
            
        case "completion":
            return targetCount
            
        default:
            return nil
        }
    }
}
