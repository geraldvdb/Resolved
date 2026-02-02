//
//  ResolvedApp.swift
//  Resolved
//
//  A habit tracking app that helps users build and maintain positive habits
//  through goal setting, progress tracking, and reward-based motivation.
//
//  Created by Gerald Van Den Berg on 12/30/24.
//

import SwiftUI
import SwiftData

@main
struct ResolvedApp: App {
    
    /// Shared model container configured for CloudKit sync with local fallback
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Resolution.self,
            LogEntry.self,
            Reward.self
        ])
        
        // Try CloudKit first, fall back to local storage if it fails
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // Fall back to local-only storage
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
