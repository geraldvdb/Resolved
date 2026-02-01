import Foundation
import SwiftData

@Model
final class LogEntry {
    // CloudKit requires default values for all stored properties
    var id: UUID = UUID()
    var date: Date = Date()
    var descriptionText: String = ""
    var resolution: Resolution?
    
    init(date: Date = Date(), descriptionText: String = "") {
        self.id = UUID()
        self.date = date
        self.descriptionText = descriptionText
    }
}
