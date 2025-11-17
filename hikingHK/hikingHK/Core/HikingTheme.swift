//
//  HikingTheme.swift
//  hikingHK
//
//  Created for hiking theme colors and styles
//

import SwiftUI

extension Color {
    // 远足主题颜色
    static let hikingGreen = Color(red: 0.2, green: 0.6, blue: 0.4) // 森林绿
    static let hikingDarkGreen = Color(red: 0.15, green: 0.45, blue: 0.3) // 深绿
    static let hikingBrown = Color(red: 0.6, green: 0.45, blue: 0.3) // 土棕色
    static let hikingTan = Color(red: 0.85, green: 0.75, blue: 0.6) // 浅棕色
    static let hikingEarth = Color(red: 0.5, green: 0.4, blue: 0.3) // 大地色
    static let hikingSky = Color(red: 0.4, green: 0.6, blue: 0.8) // 天空蓝
    static let hikingStone = Color(red: 0.5, green: 0.5, blue: 0.5) // 石灰色
    
    // 渐变
    static let hikingGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.55, blue: 0.4),
            Color(red: 0.35, green: 0.65, blue: 0.5)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let hikingCardGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.98, blue: 0.95),
            Color(red: 0.92, green: 0.95, blue: 0.92)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let hikingWarmGradient = LinearGradient(
        colors: [
            Color(red: 0.9, green: 0.85, blue: 0.75),
            Color(red: 0.85, green: 0.8, blue: 0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    // 远足风格的卡片样式
    func hikingCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.hikingCardGradient)
                    .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
            )
    }
    
    // 远足风格的按钮样式
    func hikingButton(style: HikingButtonStyle = .primary) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(style == .primary ? Color.hikingGreen : Color.hikingTan)
                    .shadow(color: style == .primary ? Color.hikingGreen.opacity(0.3) : Color.hikingBrown.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .foregroundStyle(style == .primary ? .white : .primary)
    }
    
    // 远足风格的徽章样式
    func hikingBadge(color: Color = .hikingGreen) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundStyle(color)
    }
}

enum HikingButtonStyle {
    case primary
    case secondary
}

