//  DailySummaryView.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import SwiftUI
import Charts

struct DailySummaryView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedDate: Date = Date()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date Selector
                HStack {
                    Button(action: {
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: selectedDate))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
                            if tomorrow <= Date() {
                                selectedDate = tomorrow
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(Calendar.current.isDateInToday(selectedDate) ? .gray : .blue)
                    }
                    .disabled(Calendar.current.isDateInToday(selectedDate))
                }
                .padding(.horizontal)
                
                // Status Message
                StatusBanner(status: dataManager.healthStatus)
                    .padding(.horizontal)
                
                // Progress Cards
                HStack(spacing: 16) {
                    // Water Progress
                    ProgressCard(
                        title: "Water",
                        icon: "drop.fill",
                        color: .blue,
                        progress: dataManager.waterProgress,
                        detail: String(format: "%.1f/%.1fL", dataManager.dailyWater, dataManager.waterTarget)
                    )
                    
                    // Calorie Progress
                    ProgressCard(
                        title: "Calories",
                        icon: "flame.fill",
                        color: dataManager.isOverCalorieTarget ? .orange : .green,
                        progress: dataManager.calorieProgress,
                        detail: "\(dataManager.dailyCalories)/\(dataManager.calorieTarget)"
                    )
                }
                .padding(.horizontal)
                
                // Daily Statistics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Statistics")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        StatRow(
                            icon: "clock.arrow.circlepath",
                            title: "Yesterday",
                            value: "\(dataManager.previousDayCalories) cal"
                        )
                        
                        StatRow(
                            icon: "chart.bar.fill",
                            title: "30-Day Average",
                            value: "\(dataManager.averageDailyCalories) cal"
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // Consumption History
                if Calendar.current.isDateInToday(selectedDate) {
                    ConsumptionHistoryView(items: dataManager.getConsumptionItems(for: selectedDate))
                        .padding(.top)
                } else {
                    ConsumptionHistoryView(items: dataManager.getConsumptionItems(for: selectedDate))
                        .padding(.top)
                }
                
                // Weekly Chart
                WeeklyChartView()
                    .frame(height: 220)
                    .padding()
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct StatusBanner: View {
    let status: HealthStatus
    
    var icon: String {
        switch status {
        case .excellent: return "star.fill"
        case .needsWater: return "drop.fill"
        case .needsCalories: return "flame.fill"
        case .normal: return "heart.fill"
        }
    }
    
    var color: Color {
        switch status {
        case .excellent: return .yellow
        case .needsWater: return .blue
        case .needsCalories: return .orange
        case .normal: return .green
        }
    }
    
    var message: String {
        switch status {
        case .excellent: return "Perfect Balance! 🌟"
        case .needsWater: return "Need more water! 💧"
        case .needsCalories: return "Need more calories! 🔥"
        case .normal: return "Keep it up! 💪"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProgressCard: View {
    let title: String
    let icon: String
    let color: Color
    let progress: Double
    let detail: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(.title2, design: .rounded))
                        .bold()
                }
            }
            .frame(height: 100)
            
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct ConsumptionHistoryView: View {
    let items: [ConsumptionItem]
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Consumption")
                .font(.headline)
                .padding(.horizontal)
            
            if items.isEmpty {
                HStack {
                    Spacer()
                    Text("No items recorded")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ForEach(items.sorted(by: { $0.timestamp > $1.timestamp })) { item in
                    HStack {
                        Image(systemName: item.mealCategory.icon)
                            .foregroundColor(item.mealCategory.color)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text(item.mealCategory.rawValue.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(timeFormatter.string(from: item.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let water = item.waterAmount {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f L", water))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Text("\(item.calories) cal")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct WeeklyChartView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    private var weekData: [(day: String, calories: Int, water: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayName = dayFormatter.string(from: date)
            
            let items = dataManager.getConsumptionItems(for: date)
            let calories = items.reduce(0) { $0 + $1.calories }
            let water = items.reduce(0.0) { $0 + ($1.waterAmount ?? 0) }
            
            return (day: dayName, calories: calories, water: water)
        }.reversed()
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Overview")
                .font(.headline)
            
            Chart {
                ForEach(weekData, id: \.day) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Calories", data.calories)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    
                    LineMark(
                        x: .value("Day", data.day),
                        y: .value("Water", data.water * 500) // Scale water to be visible alongside calories
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let calValue = value.as(Int.self) {
                            Text("\(calValue)")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let waterValue = value.as(Int.self) {
                            let liters = Double(waterValue) / 500
                            Text(String(format: "%.1fL", liters))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .center, spacing: 20) {
                HStack(spacing: 20) {
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.orange)
                            .frame(width: 16, height: 8)
                        Text("Calories")
                            .font(.caption)
                    }
                    
                    HStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("Water (L)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    DailySummaryView()
        .environmentObject(DataManager.shared)
}
