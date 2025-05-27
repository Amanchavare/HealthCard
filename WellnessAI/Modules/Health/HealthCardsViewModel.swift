//
//  HealthCardsViewModel.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/19/23.
//

import Foundation
import CoreData

extension HealthCardsView {
    @MainActor class ViewModel: ObservableObject {
        
        private var context: NSManagedObjectContext?
        
        @Published private(set) var userSessions: [UserSession] = []
        
        func setup(context: NSManagedObjectContext) {
            self.context = context
            
            // Loading user sessions from database
            loadUserSessions()
        }
        
        private func loadUserSessions() -> Void {
            guard let context = context else { return }

            var userSessions: [UserSession] = []
            for userSession in try! context.fetch(UserSession.fetchWithHealthRequest()) {
                userSessions.append(userSession)
            }
            self.userSessions = userSessions
        }
        
    }
}
