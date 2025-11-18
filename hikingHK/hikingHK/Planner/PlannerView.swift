//
//  PlannerView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI

struct PlannerView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedTrail: Trail?
    @State private var plannedDate = Date().addingTimeInterval(60 * 60 * 24)
    @State private var note = ""
    @State private var showSaveSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose trail") {
                    Picker("Trail", selection: $selectedTrail) {
                        ForEach(viewModel.trails) { trail in
                            Text(trail.name).tag(Optional(trail))
                        }
                    }
                }
                Section("Schedule") {
                    DatePicker("Date", selection: $plannedDate, displayedComponents: .date)
                    TextField("Note (meet point, gear...)", text: $note)
                }
                Section("Preview") {
                    if let trail = selectedTrail {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trail.name)
                                .font(.headline)
                            Label(trail.district, systemImage: "mappin.and.ellipse")
                            Label {
                                Text("\(trail.lengthKm.formatted(.number.precision(.fractionLength(1)))) km • \(trail.estimatedDurationMinutes / 60) h")
                            } icon: {
                                Image(systemName: "clock")
                            }
                        }
                    } else {
                        Text("Select a trail to see summary")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
            .navigationTitle("Planner")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let trail = selectedTrail {
                            viewModel.addSavedHike(for: trail, scheduledDate: plannedDate, note: note)
                            // Reset form after saving
                            note = ""
                            selectedTrail = nil
                            plannedDate = Date().addingTimeInterval(60 * 60 * 24)
                            showSaveSuccess = true
                        }
                    }
                    .disabled(selectedTrail == nil)
                }
            }
            .alert("Plan saved", isPresented: $showSaveSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your hike has been added to your plans.")
            }
        }
    }
}

#Preview {
    PlannerView()
        .environmentObject(AppViewModel())
}

