//  ConsumptionItem.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import Foundation
import SwiftData

enum MealCategory: String, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    case drink
}

@Model
final class ConsumptionItem: Identifiable {
    var id: UUID
    var category: String // Will store the raw value of MealCategory
    var calories: Int
    var timestamp: Date
    var waterAmount: Double? // in liters
    
    // Computed property to convert string to MealCategory
    var mealCategory: MealCategory {
        get {
            return MealCategory(rawValue: category) ?? .snack
        }
        set {
            category = newValue.rawValue
        }
    }
    
    init(id: UUID = UUID(), category: MealCategory, calories: Int, timestamp: Date, waterAmount: Double? = nil) {
        self.id = id
        self.category = category.rawValue
        self.calories = calories
        self.timestamp = timestamp
        self.waterAmount = waterAmount
    }
}

// Extension for icon representation
extension MealCategory {
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        case .drink: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        case .drink: return .blue
        }
    }
}

import SwiftUI
