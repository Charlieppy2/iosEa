//
//  GearChecklistView.swift
//  hikingHK
//
//  Created for smart gear checklist UI
//

import SwiftUI
import SwiftData

struct GearChecklistView: View {
    let trail: Trail
    let weather: WeatherSnapshot
    let scheduledDate: Date
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel: GearChecklistViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.gearItems.isEmpty {
                    ContentUnavailableView(
                        languageManager.localizedString(for: "gear.no.items"),
                        systemImage: "backpack.fill",
                        description: Text(languageManager.localizedString(for: "gear.generate.description"))
                    )
                } else {
                    List {
                        // Progress Section
                        if !viewModel.gearItems.isEmpty {
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(languageManager.localizedString(for: "gear.progress"))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(viewModel.completedCount) / \(viewModel.totalCount)")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    
                                    ProgressView(value: Double(viewModel.completedCount), total: Double(viewModel.totalCount))
                                        .tint(viewModel.isAllRequiredCompleted ? .green : .blue)
                                    
                                    if viewModel.isAllRequiredCompleted {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text(languageManager.localizedString(for: "gear.all.required.complete"))
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        }
                                    } else {
                                        HStack {
                                            Text(languageManager.localizedString(for: "gear.required.items"))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text("\(viewModel.requiredCompletedCount) / \(viewModel.requiredTotalCount)")
                                                .font(.caption.weight(.semibold))
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Items by Category
                        ForEach(GearItem.GearCategory.allCases, id: \.self) { category in
                            if let items = viewModel.itemsByCategory[category], !items.isEmpty {
                                Section {
                                    ForEach(items) { item in
                                        gearItemRow(item)
                                    }
                                } header: {
                                    HStack {
                                        Image(systemName: category.icon)
                                        Text(languageManager.localizedString(for: "gear.category.\(category.rawValue.lowercased())"))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(languageManager.localizedString(for: "gear.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "done")) {
                        viewModel.saveGearItems()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.generateGearList(for: trail, weather: weather, scheduledDate: scheduledDate)
                        viewModel.saveGearItems()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.configureIfNeeded(context: modelContext)
                viewModel.loadGearItems(for: trail.id)
                
                // Generate if no items exist
                if viewModel.gearItems.isEmpty {
                    viewModel.generateGearList(for: trail, weather: weather, scheduledDate: scheduledDate)
                }
            }
        }
    }
    
    private func gearItemRow(_ item: GearItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .foregroundStyle(item.isCompleted ? .green : (item.isRequired ? .orange : .secondary))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                
                if item.isRequired {
                    Text(languageManager.localizedString(for: "gear.required"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
            
            if item.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.toggleItem(item)
        }
    }
}

#Preview {
    GearChecklistView(
        trail: Trail.sampleData[0],
        weather: WeatherSnapshot.hongKongMorning,
        scheduledDate: Date()
    )
    .modelContainer(for: [GearItem.self])
    .environmentObject(LanguageManager.shared)
}

