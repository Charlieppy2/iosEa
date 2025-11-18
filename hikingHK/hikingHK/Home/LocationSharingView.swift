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
            .navigationTitle("位置分享")
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
            .alert("確認發送緊急求救", isPresented: $isShowingSOSConfirmation) {
                Button("取消", role: .cancel) { }
                Button("發送", role: .destructive) {
                    Task {
                        await viewModel.sendEmergencySOS()
                    }
                }
            } message: {
                Text("這將向所有緊急聯繫人發送您的位置和求救信息。請確認這是緊急情況。")
            }
            .alert("錯誤", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
                Button("確定") {
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
                    Text(viewModel.isSharing ? "正在分享位置" : "未分享位置")
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    Text(viewModel.isSharing ? "您的實時位置正在分享給緊急聯繫人" : "點擊下方按鈕開始分享位置")
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
                    Text(viewModel.isSharing ? "停止分享" : "開始分享")
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
                Text("緊急求救")
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
                Text("異常檢測")
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
                Spacer()
                Text(anomaly.severity.severityText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(anomalyColor(for: anomaly.severity).opacity(0.2), in: Capsule())
                    .foregroundStyle(anomalyColor(for: anomaly.severity))
            }
            
            Text(anomaly.message)
                .font(.subheadline)
                .foregroundStyle(Color.hikingBrown)
            
            Text("檢測時間：\(anomaly.detectedAt, style: .time)")
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
                Text("當前位置")
                    .font(.headline)
                    .foregroundStyle(Color.hikingDarkGreen)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "緯度", value: String(format: "%.6f", location.coordinate.latitude))
                InfoRow(label: "經度", value: String(format: "%.6f", location.coordinate.longitude))
                if let altitude = viewModel.currentLocation?.altitude {
                    InfoRow(label: "海拔", value: String(format: "%.0f 米", altitude))
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
                Text("分享鏈接")
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
                    Text("複製鏈接")
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
                Text("緊急聯繫人")
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
                    Text("尚未添加緊急聯繫人")
                        .font(.subheadline)
                        .foregroundStyle(Color.hikingBrown)
                    Text("請添加至少一個緊急聯繫人以使用位置分享和緊急求救功能")
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
                Section("聯繫人信息") {
                    TextField("姓名", text: $newContactName)
                    TextField("電話號碼", text: $newContactPhone)
                        .keyboardType(.phonePad)
                    TextField("電子郵件（可選）", text: $newContactEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("添加緊急聯繫人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isShowingAddContact = false
                        resetContactForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundStyle(Color.hikingDarkGreen)
                    if contact.isPrimary {
                        Text("主要")
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
}

