//  FoodieApp.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import SwiftUI
import SwiftData

@main
struct FoodieApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
        .modelContainer(for: ConsumptionItem.self)
    }
}
