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
    
    // 应用背景渐变
    static let hikingBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.99, blue: 0.97), // 非常浅的绿色
            Color(red: 0.96, green: 0.98, blue: 0.95), // 浅绿色
            Color(red: 0.94, green: 0.97, blue: 0.93)  // 稍深的浅绿色
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // 页面背景颜色
    static let hikingBackground = Color(red: 0.97, green: 0.98, blue: 0.96)
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
    
    // 远足风格的背景
    func hikingBackground() -> some View {
        self
            .background(
                ZStack {
                    // 基础渐变背景
                    Color.hikingBackgroundGradient
                    
                    // 图案背景
                    HikingPatternBackground()
                        .opacity(0.15)
                }
                .ignoresSafeArea()
            )
    }
    
    // 带图片/图案的背景
    func hikingBackgroundWithPattern() -> some View {
        self
            .background(
                ZStack {
                    // 基础渐变背景
                    Color.hikingBackgroundGradient
                    
                    // 图案背景（更明显）
                    HikingPatternBackground()
                        .opacity(0.25)
                }
                .ignoresSafeArea()
            )
    }
}

// 远足主题图案背景视图
struct HikingPatternBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 山脉图案
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.hikingGreen.opacity(0.1))
                        .position(
                            x: geometry.size.width * (0.2 + Double(index) * 0.3),
                            y: geometry.size.height * (0.1 + Double(index) * 0.15)
                        )
                }
                
                // 树木图案
                ForEach(0..<4, id: \.self) { index in
                    Image(systemName: "tree.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.hikingDarkGreen.opacity(0.08))
                        .position(
                            x: geometry.size.width * (0.15 + Double(index) * 0.25),
                            y: geometry.size.height * (0.7 + Double(index % 2) * 0.1)
                        )
                }
                
                // 云朵图案
                ForEach(0..<2, id: \.self) { index in
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.hikingSky.opacity(0.06))
                        .position(
                            x: geometry.size.width * (0.3 + Double(index) * 0.4),
                            y: geometry.size.height * 0.2
                        )
                }
                
                // 路径线条
                Path { path in
                    let startY = geometry.size.height * 0.85
                    path.move(to: CGPoint(x: 0, y: startY))
                    path.addCurve(
                        to: CGPoint(x: geometry.size.width, y: startY + 20),
                        control1: CGPoint(x: geometry.size.width * 0.3, y: startY - 10),
                        control2: CGPoint(x: geometry.size.width * 0.7, y: startY + 30)
                    )
                }
                .stroke(Color.hikingBrown.opacity(0.1), lineWidth: 2)
            }
        }
    }
}

enum HikingButtonStyle {
    case primary
    case secondary
}

