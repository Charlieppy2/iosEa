//
//  LocationSharingView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import SwiftData
import CoreLocation

struct LocationSharingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel: LocationSharingViewModel
    @State private var isShowingAddContact = false
    @State private var newContactName = ""
    @State private var newContactPhone = ""
    @State private var newContactEmail = ""
    @State private var isShowingSOSConfirmation = false
    
    init(locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: LocationSharingViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 狀態卡片
                    statusCard
                    
                    // 緊急求救按鈕
                    emergencySOSButton
                    
                    // 異常檢測狀態
                    if let anomaly = viewModel.lastAnomaly {
                        anomalyAlertCard(anomaly)
                    }
                    
                    // 當前位置信息
                    if viewModel.isSharing, let location = viewModel.currentLocation {
                        locationInfoCard(location)
                    }
                    
                    // 分享鏈接
                    if viewModel.isSharing, let shareLink = viewModel.generateShareLink() {
                        shareLinkCard(shareLink)
                    }
                    
                    // 緊急聯繫人列表
                    emergencyContactsSection
                }
                .padding(20)
            }
            .navigationTitle(languageManager.localizedString(for: "home.location.share"))
            .background(
                ZStack {
                    Color.hikingBackgroundGradient
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddContact = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddContact) {
                addContactSheet
            }
            .alert(languageManager.localizedString(for: "location.share.confirm.sos"), isPresented: $isShowingSOSConfirmation) {
                Button(languageManager.localizedString(for: "cancel"), role: .cancel) { }
                Button(languageManager.localizedString(for: "location.share.send"), role: .destructive) {
                    Task {
                        await viewModel.sendEmergencySOS()
                    }
                }
            } message: {
                Text(languageManager.localizedString(for: "location.share.sos.message"))
            }
            .alert(languageManager.localizedString(for: "error"), isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
                Button(languageManager.localizedString(for: "ok")) {
                    viewModel.error = nil
                }
            } message: { error in
                Text(error)
            }
            .onAppear {
                viewModel.configureIfNeeded(context: modelContext)
            }
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: viewModel.isSharing ? "location.fill" : "location.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(viewModel.isSharing ? Color.hikingGreen : Color.hikingStone)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isSharing ? languageManager.localizedString(for: "location.share.sharing") : languageManager.localizedString(for: "location.share.not.sharing"))
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(viewModel.isSharing ? languageManager.localizedString(for: "location.share.sharing.description") : languageManager.localizedString(for: "location.share.start.description"))
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                }
                
                Spacer()
            }
            
            Button {
                if viewModel.isSharing {
                    viewModel.stopLocationSharing()
                } else {
                    viewModel.startLocationSharing()
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.isSharing ? "stop.circle.fill" : "play.circle.fill")
                    Text(viewModel.isSharing ? languageManager.localizedString(for: "location.share.stop") : languageManager.localizedString(for: "location.share.start"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isSharing ? Color.red.opacity(0.1) : Color.hikingGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(viewModel.isSharing ? .red : Color.hikingGreen)
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var emergencySOSButton: some View {
        Button {
            isShowingSOSConfirmation = true
        } label: {
            HStack {
                Image(systemName: "sos")
                    .font(.system(size: 24))
                Text(languageManager.localizedString(for: "location.share.emergency.sos"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.red, .red.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .foregroundStyle(.white)
            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isSendingSOS || viewModel.emergencyContacts.isEmpty)
        .opacity(viewModel.isSendingSOS || viewModel.emergencyContacts.isEmpty ? 0.6 : 1.0)
    }
    
    private func anomalyAlertCard(_ anomaly: Anomaly) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: anomalyIcon(for: anomaly.severity))
                    .foregroundStyle(anomalyColor(for: anomaly.severity))
                Text(languageManager.localizedString(for: "location.share.anomaly.detection"))
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                Text(anomaly.severity.localizedSeverityText(languageManager: languageManager))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(anomalyColor(for: anomaly.severity).opacity(0.2), in: Capsule())
                    .foregroundStyle(anomalyColor(for: anomaly.severity))
            }
            
            Text(anomaly.message)
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
            
            Text("\(languageManager.localizedString(for: "location.share.detected.at")): \(anomaly.detectedAt, style: .time)")
                .font(.caption)
                .foregroundStyle(Color.hikingStone)
        }
        .padding()
        .background(anomalyColor(for: anomaly.severity).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(anomalyColor(for: anomaly.severity).opacity(0.3), lineWidth: 2)
        )
    }
    
    private func locationInfoCard(_ location: CLLocation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.hikingGreen)
                Text(languageManager.localizedString(for: "location.share.current.location"))
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: languageManager.localizedString(for: "location.share.latitude"), value: String(format: "%.6f", location.coordinate.latitude))
                InfoRow(label: languageManager.localizedString(for: "location.share.longitude"), value: String(format: "%.6f", location.coordinate.longitude))
                if let altitude = viewModel.currentLocation?.altitude {
                    InfoRow(label: languageManager.localizedString(for: "location.share.altitude"), value: String(format: "%.0f m", altitude))
                }
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private func shareLinkCard(_ link: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(Color.hikingGreen)
                Text(languageManager.localizedString(for: "location.share.share.link"))
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            Text(link)
                .font(.caption)
                .foregroundStyle(Color.hikingBrown)
                .textSelection(.enabled)
            
            Button {
                UIPasteboard.general.string = link
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text(languageManager.localizedString(for: "location.share.copy.link"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.hikingGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.hikingGreen)
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(languageManager.localizedString(for: "location.share.emergency.contacts"))
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                Text("\(viewModel.emergencyContacts.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.hikingGreen.opacity(0.2), in: Capsule())
                    .foregroundStyle(Color.hikingGreen)
            }
            
            if viewModel.emergencyContacts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.hikingStone)
                    Text(languageManager.localizedString(for: "location.share.no.emergency.contacts"))
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                    Text(languageManager.localizedString(for: "location.share.add.contact.description"))
                        .font(.caption)
                        .foregroundStyle(Color.hikingStone)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hikingCardGradient.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(viewModel.emergencyContacts) { contact in
                    ContactRow(contact: contact) {
                        viewModel.removeEmergencyContact(contact)
                    }
                }
            }
        }
        .padding()
        .background(Color.hikingCardGradient, in: RoundedRectangle(cornerRadius: 16))
        .hikingCard()
    }
    
    private var addContactSheet: some View {
        NavigationStack {
            Form {
                Section(languageManager.localizedString(for: "location.share.contact.information")) {
                    TextField(languageManager.localizedString(for: "location.share.contact.name"), text: $newContactName)
                    TextField(languageManager.localizedString(for: "location.share.contact.phone"), text: $newContactPhone)
                        .keyboardType(.phonePad)
                    TextField(languageManager.localizedString(for: "location.share.contact.email"), text: $newContactEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle(languageManager.localizedString(for: "location.share.add.emergency.contact"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(languageManager.localizedString(for: "cancel")) {
                        isShowingAddContact = false
                        resetContactForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(languageManager.localizedString(for: "save")) {
                        let contact = EmergencyContact(
                            name: newContactName,
                            phoneNumber: newContactPhone,
                            email: newContactEmail.isEmpty ? nil : newContactEmail
                        )
                        viewModel.addEmergencyContact(contact)
                        isShowingAddContact = false
                        resetContactForm()
                    }
                    .disabled(newContactName.isEmpty || newContactPhone.isEmpty)
                }
            }
        }
    }
    
    private func resetContactForm() {
        newContactName = ""
        newContactPhone = ""
        newContactEmail = ""
    }
    
    private func anomalyIcon(for severity: Anomaly.Severity) -> String {
        switch severity {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    private func anomalyColor(for severity: Anomaly.Severity) -> Color {
        switch severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.hikingBrown)
            Spacer()
            Text(value)
                .foregroundStyle(Color.hikingDarkGreen)
                .fontWeight(.medium)
        }
    }
}

struct ContactRow: View {
    let contact: EmergencyContact
    let onDelete: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    if contact.isPrimary {
                        Text(languageManager.localizedString(for: "location.share.primary"))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.hikingGreen.opacity(0.2), in: Capsule())
                            .foregroundStyle(Color.hikingGreen)
                    }
                }
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundStyle(Color.hikingBrown)
                if let email = contact.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(Color.hikingStone)
                }
            }
            Spacer()
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}


#Preview {
    LocationSharingView(locationManager: LocationManager())
        .modelContainer(for: [EmergencyContact.self, LocationShareSession.self], inMemory: true)
        .environmentObject(LanguageManager.shared)
}

