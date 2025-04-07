//  ContentView.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        TabView {
            NavigationView {
                DailySummaryView()
                    .navigationTitle("Summary")
            }
            .tabItem {
                Label("Summary", systemImage: "chart.bar.fill")
            }
            
            NavigationView {
                AddConsumptionView()
                    .navigationTitle("Add")
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle.fill")
            }
            
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
