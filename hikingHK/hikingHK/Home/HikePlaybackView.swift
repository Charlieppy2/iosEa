//
//  HikePlaybackView.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct HikePlaybackView: View {
    let record: HikeRecord
    @Environment(\.dismiss) private var dismiss
    @State private var playbackProgress: Double = 0
    @State private var isPlaying: Bool = false
    @State private var playbackSpeed: Double = 1.0 // 回放速度倍數
    @State private var currentIndex: Int = 0
    
    private var currentPoint: HikeTrackPoint? {
        guard !record.trackPoints.isEmpty, currentIndex < record.trackPoints.count else { return nil }
        return record.trackPoints[currentIndex]
    }
    
    private var displayedPoints: [HikeTrackPoint] {
        guard !record.trackPoints.isEmpty else { return [] }
        let endIndex = min(currentIndex + 1, record.trackPoints.count)
        return Array(record.trackPoints[0..<endIndex])
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 3D 地圖
                if let current = currentPoint {
                    Map(position: .constant(.camera(MapCamera(
                        centerCoordinate: current.coordinate,
                        distance: 1000,
                        heading: calculateHeading(),
                        pitch: 60
                    )))) {
                        // 已走過的路線
                        if displayedPoints.count > 1 {
                            MapPolyline(coordinates: displayedPoints.map { $0.coordinate })
                                .stroke(Color.hikingGreen, lineWidth: 4)
                        }
                        
                        // 未走的路線（灰色）
                        if currentIndex < record.trackPoints.count - 1 {
                            let remainingPoints = Array(record.trackPoints[currentIndex..<record.trackPoints.count])
                            MapPolyline(coordinates: remainingPoints.map { $0.coordinate })
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        }
                        
                        // 當前位置
                        Annotation("當前位置", coordinate: current.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 16, height: 16)
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                        // 起點
                        if let start = record.trackPoints.first {
                            Annotation("起點", coordinate: start.coordinate) {
                                Image(systemName: "flag.fill")
                                    .foregroundStyle(.green)
                                    .font(.title2)
                            }
                        }
                        
                        // 終點
                        if let end = record.trackPoints.last {
                            Annotation("終點", coordinate: end.coordinate) {
                                Image(systemName: "flag.checkered")
                                    .foregroundStyle(.red)
                                    .font(.title2)
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .ignoresSafeArea()
                } else {
                    Color.hikingBackgroundGradient
                        .ignoresSafeArea()
                }
                
                VStack {
                    Spacer()
                    
                    // 控制面板
                    controlPanel
                        .padding()
                }
            }
            .navigationTitle("3D 軌跡回放")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                currentIndex = 0
                playbackProgress = 0
            }
        }
    }
    
    private var controlPanel: some View {
        VStack(spacing: 16) {
            // 進度條
            VStack(spacing: 8) {
                HStack {
                    Text("進度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(playbackProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $playbackProgress, in: 0...1) { editing in
                    if !editing {
                        updateIndexFromProgress()
                    }
                }
                .tint(Color.hikingGreen)
                
                HStack {
                    Text(formatTime(for: currentIndex))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatTime(for: record.trackPoints.count - 1))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 統計信息
            if let current = currentPoint {
                HStack(spacing: 16) {
                    InfoBadge(icon: "mountain.2.fill", value: String(format: "%.0f m", current.altitude), color: Color.hikingGreen)
                    InfoBadge(icon: "speedometer", value: String(format: "%.1f km/h", current.speedKmh), color: Color.hikingSky)
                    InfoBadge(icon: "location.fill", value: "\(currentIndex + 1)/\(record.trackPoints.count)", color: Color.hikingBrown)
                }
            }
            
            // 控制按鈕
            HStack(spacing: 12) {
                // 速度控制
                Menu {
                    Button("0.5x") { playbackSpeed = 0.5 }
                    Button("1x") { playbackSpeed = 1.0 }
                    Button("2x") { playbackSpeed = 2.0 }
                    Button("4x") { playbackSpeed = 4.0 }
                } label: {
                    HStack {
                        Image(systemName: "gauge")
                        Text("\(playbackSpeed, specifier: "%.1f")x")
                    }
                    .padding()
                    .background(Color.hikingGreen.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.hikingGreen)
                }
                
                // 播放/暫停
                Button {
                    isPlaying.toggle()
                    if isPlaying {
                        startPlayback()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.hikingGreen, in: Circle())
                        .foregroundStyle(.white)
                }
                
                // 重置
                Button {
                    currentIndex = 0
                    playbackProgress = 0
                    isPlaying = false
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.hikingBrown.opacity(0.1), in: Circle())
                        .foregroundStyle(Color.hikingBrown)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
    
    private func startPlayback() {
        guard isPlaying, currentIndex < record.trackPoints.count - 1 else {
            isPlaying = false
            return
        }
        
        Task {
            while isPlaying && currentIndex < record.trackPoints.count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / playbackSpeed)) // 根據速度調整間隔
                
                if isPlaying {
                    currentIndex += 1
                    playbackProgress = Double(currentIndex) / Double(max(record.trackPoints.count - 1, 1))
                    
                    if currentIndex >= record.trackPoints.count - 1 {
                        isPlaying = false
                    }
                }
            }
        }
    }
    
    private func updateIndexFromProgress() {
        let newIndex = Int(playbackProgress * Double(max(record.trackPoints.count - 1, 0)))
        currentIndex = min(newIndex, record.trackPoints.count - 1)
    }
    
    private func calculateHeading() -> Double {
        guard currentIndex < record.trackPoints.count - 1 else { return 0 }
        let current = record.trackPoints[currentIndex]
        let next = record.trackPoints[currentIndex + 1]
        
        let lat1 = current.latitude.toRadians()
        let lon1 = current.longitude.toRadians()
        let lat2 = next.latitude.toRadians()
        let lon2 = next.longitude.toRadians()
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return bearing.toDegrees()
    }
    
    private func formatTime(for index: Int) -> String {
        guard index < record.trackPoints.count else { return "00:00" }
        let point = record.trackPoints[index]
        let timeInterval = point.timestamp.timeIntervalSince(record.startTime)
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d:%02d", minutes, Int(timeInterval) % 60)
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption.bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1), in: Capsule())
        .foregroundStyle(color)
    }
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

#Preview {
    HikePlaybackView(record: HikeRecord())
}

