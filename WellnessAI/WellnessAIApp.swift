//
//  WellnessAIApp.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 11/22/23.
//

import SwiftUI
import CoreData

@main
struct WellnessAIApp: App {
    
    private let container = NSPersistentContainer(name: Keys.APPLICATION_NAME)
    private let defaults = UserDefaults.standard
    
    init() {
        // Loading persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        
        // Setting up user session
        defaults.set(UUID().uuidString, forKey: Keys.LAST_USER_SESSSION)
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, container.viewContext)
        }
    }
}
