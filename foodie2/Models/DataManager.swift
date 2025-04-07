//  DataManager.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import Foundation
import SwiftUI
import UserNotifications
import SwiftData

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published private(set) var dailyCalories: Int = 0
    @Published private(set) var dailyWater: Double = 0
    @Published private(set) var waterTarget: Double = 2.0  // Default value
    @Published private(set) var calorieTarget: Int = 2000  // Default value
    @Published var consumptionHistory: [ConsumptionItem] = []
    
    private let calendar = Calendar.current
    private let database = SwiftDataManager.shared
    
    private init() {
        Task {
            // Load saved values from database
            if let waterTargetStr = database.getSetting(key: "WaterTarget"),
               let waterTargetValue = Double(waterTargetStr) {
                waterTarget = waterTargetValue
            }
            
            if let calorieTargetStr = database.getSetting(key: "CalorieTarget"),
               let calorieTargetValue = Int(calorieTargetStr) {
                calorieTarget = calorieTargetValue
            }
            
            // Load consumption history from database
            await loadConsumptionHistory()
            
            // Calculate today's totals
            calculateTodayTotals()
            
            // Setup midnight reset
            setupMidnightReset()
            
            // Request notification permissions
            requestNotificationPermissions()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadConsumptionHistory() async {
        consumptionHistory = database.getAllConsumptionItems()
    }
    
    private func calculateTodayTotals() {
        let todayItems = getConsumptionItems(for: Date())
        
        dailyCalories = todayItems.reduce(0) { $0 + $1.calories }
        dailyWater = todayItems.reduce(0.0) { $0 + ($1.waterAmount ?? 0) }
    }
    
    // MARK: - Computed Properties
    
    var previousDayCalories: Int {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return getConsumptionItems(for: yesterday).reduce(0) { $0 + $1.calories }
    }
    
    var averageDailyCalories: Int {
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recentHistory = consumptionHistory.filter { $0.timestamp >= thirtyDaysAgo }
        guard !recentHistory.isEmpty else { return 0 }
        
        // Group by day and calculate average
        let dailyTotals = Dictionary(grouping: recentHistory) { item in
            calendar.startOfDay(for: item.timestamp)
        }.mapValues { items in
            items.reduce(0) { $0 + $1.calories }
        }
        
        return dailyTotals.values.reduce(0, +) / max(dailyTotals.count, 1)
    }
    
    var isOverCalorieTarget: Bool {
        dailyCalories > calorieTarget
    }
    
    var calorieProgress: Double {
        Double(dailyCalories) / Double(calorieTarget)
    }
    
    var waterProgress: Double {
        dailyWater / waterTarget
    }
    
    var healthStatus: HealthStatus {
        if calorieProgress >= 1.0 && waterProgress >= 1.0 {
            return .excellent
        } else if calorieProgress >= 1.0 {
            return .needsWater
        } else if waterProgress >= 1.0 {
            return .needsCalories
        }
        return .normal
    }
    
    // MARK: - Public Methods
    
    func updateWaterTarget(_ newValue: Double) {
        waterTarget = newValue
        database.setSetting(key: "WaterTarget", value: String(newValue))
    }
    
    func updateCalorieTarget(_ newValue: Int) {
        calorieTarget = newValue
        database.setSetting(key: "CalorieTarget", value: String(newValue))
    }
    
    func addConsumption(_ item: ConsumptionItem) {
        // Save to database
        database.saveConsumptionItem(item)
        
        // Update in-memory collection
        consumptionHistory.append(item)
        
        // Update daily totals
        if let water = item.waterAmount {
            dailyWater += water
        } else {
            dailyCalories += item.calories
        }
        
        // Check if targets reached and send notification if needed
        checkTargetsAndNotify()
    }
    
    func validateIntake(calories: Int? = nil, water: Double? = nil) -> IntakeStatus {
        if let calories = calories {
            let newTotal = dailyCalories + calories
            let newProgress = Double(newTotal) / Double(calorieTarget)
            
            if newTotal > 5000 {
                return .dangerous
            } else if newProgress >= 1.5 {
                return .excessive
            } else if newProgress >= 1.0 {
                return .targetReached
            }
        }
        
        if let water = water {
            let newTotal = dailyWater + water
            let newProgress = newTotal / waterTarget
            
            if newProgress >= 2.0 {
                return .dangerous
            } else if newProgress >= 1.5 {
                return .excessive
            } else if newProgress >= 1.0 {
                return .targetReached
            }
        }
        
        return .normal
    }
    
    func resetDaily() {
        // Clear today's data from database
        database.clearConsumptionItems(forDate: Date())
        
        // Reset in-memory counters
        dailyCalories = 0
        dailyWater = 0
        
        // Reload consumption history to reflect changes
        Task {
            await loadConsumptionHistory()
        }
    }
    
    func getConsumptionItems(for date: Date) -> [ConsumptionItem] {
        return database.getConsumptionItems(forDate: date)
    }
    
    func deleteConsumptionItem(id: UUID) {
        // Delete from database
        database.deleteConsumptionItem(id: id)
        
        // Update in-memory collection
        if let index = consumptionHistory.firstIndex(where: { $0.id == id }) {
            let item = consumptionHistory[index]
            consumptionHistory.remove(at: index)
            
            // Update daily totals if item was from today
            if calendar.isDateInToday(item.timestamp) {
                if let water = item.waterAmount {
                    dailyWater -= water
                } else {
                    dailyCalories -= item.calories
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMidnightReset() {
        // Calculate time until next midnight
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let midnight = calendar.startOfDay(for: tomorrow)
        let timeUntilMidnight = midnight.timeIntervalSince(now)
        
        // Schedule reset at midnight
        DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilMidnight) { [weak self] in
            self?.resetDaily()
            // Reschedule for next day
            self?.setupMidnightReset()
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkTargetsAndNotify() {
        // Check if we just reached a target
        if calorieProgress >= 1.0 && dailyCalories - (dailyCalories % 100) == calorieTarget {
            sendNotification(
                title: "Calorie Target Reached! 🎯",
                body: "You've hit your daily calorie goal of \(calorieTarget) calories."
            )
        }
        
        if waterProgress >= 1.0 && (dailyWater * 10).rounded() / 10 == waterTarget {
            sendNotification(
                title: "Water Target Reached! 💧",
                body: "You've hit your daily water goal of \(waterTarget)L."
            )
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

enum CalorieStatus {
    case normal
    case aboveTarget
    case tooHigh
}

enum HealthStatus {
    case normal, excellent, needsWater, needsCalories
}

enum IntakeStatus {
    case normal, targetReached, excessive, dangerous
}
