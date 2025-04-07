//  AddConsumptionView.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import SwiftUI

struct AddConsumptionView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedCategory: MealCategory = .snack
    @State private var calories: String = ""
    @State private var waterAmount: String = ""
    @State private var showingConfirmation = false
    @State private var showError = false
    @State private var showAddedAlert = false
    @State private var addedItemDescription = ""
    @State private var isShowingNumberPad = true
    @State private var selectedValue: Double = 0
    @State private var calorieStatus: CalorieStatus = .normal
    @State private var alertType: AlertType? = nil
    @State private var intakeStatus: IntakeStatus = .normal
    
    enum AlertType: Identifiable {
        case success, overTarget, tooHigh, invalid
        
        var id: Int {
            switch self {
            case .success: return 0
            case .overTarget: return 1
            case .tooHigh: return 2
            case .invalid: return 3
            }
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Type")) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(MealCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.rawValue.capitalized)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.navigationLink)
            }
            
            Section(header: Text("Amount")) {
                if selectedCategory != .drink {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        TextField("Calories", text: $calories)
                            .keyboardType(.decimalPad)
                        Stepper("", value: Binding(
                            get: { Double(calories) ?? 0 },
                            set: { calories = "\(Int($0))" }
                        ), in: 0...2000, step: 49)
                        .labelsHidden()
                    }
                    
                    // Quick presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach([50, 100, 200, 300, 400], id: \.self) { value in
                                Button("\(value)") {
                                    calories = "\(value)"
                                }
                                .buttonStyle(.bordered)
                                .tint(calories == "\(value)" ? .accentColor : .secondary)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                } else {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        TextField("Water (L)", text: $waterAmount)
                            .keyboardType(.decimalPad)
                        Stepper("", value: Binding(
                            get: { Double(waterAmount) ?? 0 },
                            set: { waterAmount = String(format: "%.2f", $0) }
                        ), in: 0...5, step: 0.1)
                        .labelsHidden()
                    }
                    
                    // Quick presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach([0.25, 0.5, 0.75, 1.0, 1.5], id: \.self) { value in
                                Button("\(value, specifier: "%.2f")") {
                                    waterAmount = "\(value)"
                                }
                                .buttonStyle(.bordered)
                                .tint(waterAmount == "\(value)" ? .accentColor : .secondary)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            
            Section {
                Button(action: addConsumption) {
                    HStack {
                        Spacer()
                        Text("Add")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(!isValidInput)
                .listRowBackground(Color.blue)
                .foregroundColor(.white)
            }
        }
        .alert(item: $alertType) { type in
            let (title, message) = getAlertContent(for: type)
            return Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Item Added Successfully", isPresented: $showAddedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(addedItemDescription)
        }
        // Removed the toolbar item with the "Done" button here
    }
    
    private var isValidInput: Bool {
        if selectedCategory == .drink {
            guard let water = Double(waterAmount) else { return false }
            return water > 0 && water < 5
        } else {
            guard let calories = Int(calories) else { return false }
            return calories > 0 && calories < 5000
        }
    }
    
    private func addConsumption() {
        let newCalories = selectedCategory == .drink ? 0 : (Int(calories) ?? 0)
        let newWater = selectedCategory == .drink ? (Double(waterAmount) ?? 0) : 0
        
        intakeStatus = dataManager.validateIntake(
            calories: selectedCategory == .drink ? nil : newCalories,
            water: selectedCategory == .drink ? newWater : nil
        )
        
        switch intakeStatus {
        case .dangerous:
            alertType = .tooHigh
            return
        case .excessive:
            alertType = .overTarget
        case .targetReached:
            alertType = .success
        case .normal:
            break
        }
        
        let item = ConsumptionItem(
            id: UUID(),
            category: selectedCategory,
            calories: newCalories,
            timestamp: Date(),
            waterAmount: selectedCategory == .drink ? newWater : nil
        )
        
        // Create description for alert
        if selectedCategory == .drink {
            addedItemDescription = "Added \(newWater)L of water"
        } else {
            addedItemDescription = "Added \(newCalories) calories (\(selectedCategory.rawValue))"
        }
        
        
        
        dataManager.addConsumption(item)
        
        // Show success alert
        showAddedAlert = true
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        
    }
    
    private func getAlertContent(for type: AlertType) -> (String, String) {
        switch type {
        case .success:
            return ("Target Reached! 🎯", "Great job hitting your daily goal!")
        case .overTarget:
            return ("Watch Out! ⚠️", "You're well over your daily target. Consider slowing down.")
        case .tooHigh:
            return ("Health Warning! ⚠️", "This amount might be unsafe. Please reconsider.")
        case .invalid:
            return ("Invalid Input", "Please enter a valid amount.")
        }
    }
    
    private func clearForm() {
        calories = ""
        waterAmount = ""
    }
}



#Preview {
    NavigationView {
        AddConsumptionView()
            .environmentObject(DataManager.shared)
    }
}
