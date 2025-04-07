//  SettingsView.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var waterTarget: Double
    @State private var calorieTarget: Int
    @State private var showResetConfirmation = false
    @State private var notificationsEnabled = true
    @AppStorage("reminderTime") private var reminderTime = Date(timeIntervalSince1970: 
        TimeInterval(12 * 60 * 60)) // Default to noon
    
    init() {
        // Initialize state variables with current values from DataManager
        _waterTarget = State(initialValue: DataManager.shared.waterTarget)
        _calorieTarget = State(initialValue: DataManager.shared.calorieTarget)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Daily Targets")) {
                HStack {
                    Text("Water Target")
                    Spacer()
                    Text("\(waterTarget, specifier: "%.1f") L")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $waterTarget, in: 0.5...5.0, step: 0.1) {
                    Text("Water Target")
                } minimumValueLabel: {
                    Text("0.5L")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("5.0L")
                        .font(.caption)
                }
                .onChange(of: waterTarget) { 
                    dataManager.updateWaterTarget(waterTarget)
                }
                
                HStack {
                    Text("Calorie Target")
                    Spacer()
                    Text("\(calorieTarget) cal")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(calorieTarget) },
                    set: { calorieTarget = Int($0) }
                ), in: 1000...4000, step: 50) {
                    Text("Calorie Target")
                } minimumValueLabel: {
                    Text("1000")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("4000")
                        .font(.caption)
                }
                .onChange(of: calorieTarget) { 
                    dataManager.updateCalorieTarget(calorieTarget)
                }
            }
            
            Section(header: Text("Reminders")) {
                Toggle("Enable Reminders", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { 
                        scheduleReminder()
                    }
                
                if notificationsEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { 
                            scheduleReminder()
                        }
                }
            }
            
            Section(header: Text("History")) {
                Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset Today's Data")
                    }
                }
                .alert("Reset Today's Data", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset", role: .destructive) {
                        dataManager.resetDaily()
                    }
                } message: {
                    Text("This will reset all of today's consumption data. This action cannot be undone.")
                }
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
            }
        }
        .onAppear {
            // Refresh values when view appears
            waterTarget = dataManager.waterTarget
            calorieTarget = dataManager.calorieTarget
            
            // Schedule reminder when view appears
            scheduleReminder()
        }
    }
    
    private func scheduleReminder() {
        guard notificationsEnabled else { return }
        
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Create new notification
        let content = UNMutableNotificationContent()
        content.title = "Foodie Reminder"
        content.body = "Don't forget to log your food and water intake today!"
        content.sound = .default
        
        // Extract hour and minute components from the selected time
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        
        // Create a daily trigger at the specified time
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}
