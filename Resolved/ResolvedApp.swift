//
//  ResolvedApp.swift
//  Resolved
//
//  Created by Gerald Van Den Berg on 12/30/24.
//

import SwiftUI
import SwiftData

@main
struct ResolvedApp: App {
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
            let container = try ModelContainer(for: schema, configurations: [cloudConfig])
            print("✅ CloudKit sync ENABLED - data will sync to iCloud")
            return container
        } catch {
            print("❌ CloudKit failed: \(error)")
            print("⚠️ Falling back to local storage (no sync)")
            
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
