//  SwiftDataManager.swift
//  Foodie
//
//  Created on 4/7/2025.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    private var modelContainer: ModelContainer
    private var modelContext: ModelContext
    
    private init() {
        do {
            // Configure the model container
            let schema = Schema([ConsumptionItem.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
            
            // Insert default settings if they don't exist
            insertDefaultSettings()
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Settings Methods
    
    private var settingsKey = "AppSettings"
    
    private struct AppSettings: Codable {
        var waterTarget: Double = 2.0
        var calorieTarget: Int = 2000
    }
    
    private func insertDefaultSettings() {
        if getSetting(key: "WaterTarget") == nil {
            setSetting(key: "WaterTarget", value: "2.0")
        }
        
        if getSetting(key: "CalorieTarget") == nil {
            setSetting(key: "CalorieTarget", value: "2000")
        }
    }
    
    func setSetting(key: String, value: String) {
        var settings = getSettings()
        
        switch key {
        case "WaterTarget":
            if let waterTarget = Double(value) {
                settings.waterTarget = waterTarget
            }
        case "CalorieTarget":
            if let calorieTarget = Int(value) {
                settings.calorieTarget = calorieTarget
            }
        default:
            break
        }
        
        saveSettings(settings)
    }
    
    func getSetting(key: String) -> String? {
        let settings = getSettings()
        
        switch key {
        case "WaterTarget":
            return String(settings.waterTarget)
        case "CalorieTarget":
            return String(settings.calorieTarget)
        default:
            return nil
        }
    }
    
    private func getSettings() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return settings
        }
        return AppSettings()
    }
    
    private func saveSettings(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    // MARK: - Consumption Methods
    
    func saveConsumptionItem(_ item: ConsumptionItem) {
        modelContext.insert(item)
        try? modelContext.save()
    }
    
    func getAllConsumptionItems() -> [ConsumptionItem] {
        let descriptor = FetchDescriptor<ConsumptionItem>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching consumption items: \(error.localizedDescription)")
            return []
        }
    }
    
    func getConsumptionItems(forDate date: Date) -> [ConsumptionItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<ConsumptionItem> { item in
            item.timestamp >= startOfDay && item.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<ConsumptionItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching consumption items for date: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteConsumptionItem(id: UUID) {
        let predicate = #Predicate<ConsumptionItem> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<ConsumptionItem>(predicate: predicate)
        
        do {
            let items = try modelContext.fetch(descriptor)
            if let item = items.first {
                modelContext.delete(item)
                try modelContext.save()
            }
        } catch {
            print("Error deleting consumption item: \(error.localizedDescription)")
        }
    }
    
    func clearConsumptionItems(forDate date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<ConsumptionItem> { item in
            item.timestamp >= startOfDay && item.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<ConsumptionItem>(predicate: predicate)
        
        do {
            let items = try modelContext.fetch(descriptor)
            for item in items {
                modelContext.delete(item)
            }
            try modelContext.save()
        } catch {
            print("Error clearing consumption items: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Database Maintenance
    
    func getItemCount() -> Int {
        let descriptor = FetchDescriptor<ConsumptionItem>(sortBy: [])
        
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Error counting consumption items: \(error.localizedDescription)")
            return 0
        }
    }
}
