//
//  LogEntry.swift
//  Resolved
//
//  SwiftData model representing a single progress entry toward a resolution.
//  Each entry records when the user completed an activity and optional notes.
//

import Foundation
import SwiftData

/// A single progress entry recording when a user worked toward their resolution.
///
/// Log entries are the building blocks of progress tracking. Each entry:
/// - Records the date the activity was completed
/// - Can include optional notes about the session
/// - Is associated with exactly one resolution
@Model
final class LogEntry {
    // CloudKit requires default values for all stored properties
    var id: UUID = UUID()
    var date: Date = Date()
    var descriptionText: String = ""
    var resolution: Resolution?
    
    /// Creates a new log entry
    /// - Parameters:
    ///   - date: When the activity was completed (defaults to now)
    ///   - descriptionText: Optional notes about this entry
    init(date: Date = Date(), descriptionText: String = "") {
        self.id = UUID()
        self.date = date
        self.descriptionText = descriptionText
    }
}
