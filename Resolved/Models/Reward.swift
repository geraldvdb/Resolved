//
//  Reward.swift
//  Resolved
//
//  SwiftData model for rewards that can be unlocked at milestones
//

import Foundation
import SwiftData

@Model
final class Reward {
    // CloudKit requires default values for all stored properties
    var id: UUID = UUID()
    var descriptionText: String = ""
    var triggerType: String = "milestone"  // "segment", "milestone", "completion"
    var triggerValue: Int = 0    // e.g., 10 for every 10, 25 for at #25, 0 for completion
    var isUnlocked: Bool = false
    var unlockedAt: Date?
    var resolution: Resolution?
    
    init(
        descriptionText: String,
        triggerType: String,
        triggerValue: Int,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = UUID()
        self.descriptionText = descriptionText
        self.triggerType = triggerType
        self.triggerValue = triggerValue
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
    
    // MARK: - Display Properties
    
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
    
    /// Check if this reward should trigger at the given count
    func shouldTrigger(at count: Int, previousCount: Int, targetCount: Int) -> Bool {
        guard !isUnlocked else { return false }
        
        switch triggerType {
        case "segment":
            // Trigger when we cross a segment boundary
            guard triggerValue > 0 else { return false }
            return count > 0 && count % triggerValue == 0 && previousCount % triggerValue != 0
            
        case "milestone":
            // Trigger when we reach or cross the milestone
            return count >= triggerValue && previousCount < triggerValue
            
        case "completion":
            // Trigger when we complete all blocks
            return count >= targetCount && previousCount < targetCount
            
        default:
            return false
        }
    }
    
    /// Unlock this reward
    func unlock() {
        isUnlocked = true
        unlockedAt = Date()
    }
    
    /// Get the target number for progress display
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
