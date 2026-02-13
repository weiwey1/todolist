//
//  DesignSystem.swift
//  todolist
//

import SwiftUI

struct AppColorTokens {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let success: Color
    let danger: Color
    let warning: Color
    let border: Color
    let dueToday: Color
    let overdue: Color
    let priorityLow: Color
    let priorityMedium: Color
    let priorityHigh: Color
    let priorityUrgent: Color

    let gradientTop: Color
    let gradientBottom: Color
    let mutedSurface: Color
}

struct AppSpacingTokens {
    let xs: CGFloat = 6
    let sm: CGFloat = 10
    let md: CGFloat = 14
    let lg: CGFloat = 18
    let xl: CGFloat = 24
}

struct AppRadiusTokens {
    let sm: CGFloat = 10
    let md: CGFloat = 14
    let lg: CGFloat = 18
    let xl: CGFloat = 24
    let pill: CGFloat = 999
}

struct AppShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

struct AppShadowTokens {
    let card: AppShadowStyle
    let floating: AppShadowStyle
}

struct AppTypographyTokens {
    let title: Font
    let section: Font
    let body: Font
    let caption: Font
}

struct AppTheme {
    enum Mode {
        case light
        case dark
    }

    let mode: Mode
    let colors: AppColorTokens
    let spacing = AppSpacingTokens()
    let radius = AppRadiusTokens()
    let shadows: AppShadowTokens
    let typography = AppTypographyTokens(
        title: .system(size: 30, weight: .bold, design: .rounded),
        section: .system(size: 15, weight: .semibold, design: .rounded),
        body: .system(size: 17, weight: .medium, design: .rounded),
        caption: .system(size: 13, weight: .regular, design: .rounded)
    )

    static func resolve(for colorScheme: ColorScheme) -> AppTheme {
        colorScheme == .dark ? .dark : .light
    }

    static let light = AppTheme(
        mode: .light,
        colors: AppColorTokens(
            background: Color(red: 0.95, green: 0.97, blue: 0.98),
            surface: Color.white.opacity(0.9),
            surfaceElevated: Color.white,
            textPrimary: Color(red: 0.08, green: 0.15, blue: 0.16),
            textSecondary: Color(red: 0.33, green: 0.42, blue: 0.43),
            accent: Color(red: 0.08, green: 0.64, blue: 0.60),
            success: Color(red: 0.10, green: 0.66, blue: 0.51),
            danger: Color(red: 0.89, green: 0.31, blue: 0.34),
            warning: Color(red: 0.90, green: 0.54, blue: 0.14),
            border: Color.black.opacity(0.08),
            dueToday: Color(red: 0.96, green: 0.62, blue: 0.14),
            overdue: Color(red: 0.89, green: 0.31, blue: 0.34),
            priorityLow: Color(red: 0.30, green: 0.66, blue: 0.58),
            priorityMedium: Color(red: 0.27, green: 0.56, blue: 0.89),
            priorityHigh: Color(red: 0.94, green: 0.63, blue: 0.19),
            priorityUrgent: Color(red: 0.90, green: 0.25, blue: 0.28),
            gradientTop: Color(red: 0.89, green: 0.97, blue: 0.96),
            gradientBottom: Color(red: 0.96, green: 0.95, blue: 0.99),
            mutedSurface: Color(red: 0.93, green: 0.97, blue: 0.96)
        ),
        shadows: AppShadowTokens(
            card: AppShadowStyle(
                color: Color.black.opacity(0.05),
                radius: 14,
                x: 0,
                y: 6
            ),
            floating: AppShadowStyle(
                color: Color.black.opacity(0.1),
                radius: 22,
                x: 0,
                y: 10
            )
        )
    )

    static let dark = AppTheme(
        mode: .dark,
        colors: AppColorTokens(
            background: Color(red: 0.07, green: 0.10, blue: 0.11),
            surface: Color(red: 0.11, green: 0.15, blue: 0.16).opacity(0.95),
            surfaceElevated: Color(red: 0.13, green: 0.18, blue: 0.19),
            textPrimary: Color(red: 0.91, green: 0.96, blue: 0.95),
            textSecondary: Color(red: 0.65, green: 0.74, blue: 0.73),
            accent: Color(red: 0.20, green: 0.80, blue: 0.74),
            success: Color(red: 0.24, green: 0.83, blue: 0.62),
            danger: Color(red: 0.98, green: 0.48, blue: 0.49),
            warning: Color(red: 0.96, green: 0.63, blue: 0.28),
            border: Color.white.opacity(0.12),
            dueToday: Color(red: 0.98, green: 0.74, blue: 0.30),
            overdue: Color(red: 1.0, green: 0.52, blue: 0.50),
            priorityLow: Color(red: 0.35, green: 0.78, blue: 0.69),
            priorityMedium: Color(red: 0.41, green: 0.71, blue: 0.97),
            priorityHigh: Color(red: 0.98, green: 0.73, blue: 0.32),
            priorityUrgent: Color(red: 0.99, green: 0.45, blue: 0.48),
            gradientTop: Color(red: 0.10, green: 0.14, blue: 0.15),
            gradientBottom: Color(red: 0.07, green: 0.09, blue: 0.11),
            mutedSurface: Color(red: 0.15, green: 0.20, blue: 0.20)
        ),
        shadows: AppShadowTokens(
            card: AppShadowStyle(
                color: Color.black.opacity(0.35),
                radius: 20,
                x: 0,
                y: 10
            ),
            floating: AppShadowStyle(
                color: Color.black.opacity(0.45),
                radius: 26,
                x: 0,
                y: 12
            )
        )
    )
}

extension View {
    func appCardStyle(theme: AppTheme, elevated: Bool = false) -> some View {
        let fillColor = elevated ? theme.colors.surfaceElevated : theme.colors.surface
        return self
            .background(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
            .shadow(
                color: theme.shadows.card.color,
                radius: theme.shadows.card.radius,
                x: theme.shadows.card.x,
                y: theme.shadows.card.y
            )
    }
}
