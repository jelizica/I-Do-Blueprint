//
//  StylePreferencesSearchResultCard.swift
//  I Do Blueprint
//
//  Display style preferences in search results with proper formatting
//

import SwiftUI

struct StylePreferencesSearchResultCard: View {
    let stylePreferences: StylePreferences
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Style Preferences")
        .accessibilityHint("Tap to view and edit your wedding style preferences")
        .accessibilityValue(accessibilityDescription)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            headerSection
            primaryColorsSection
            styleInfluencesSection
            additionalDetailsSection
            visualThemesSection
        }
        .padding()
        .background(cardBackground)
        .overlay(cardBorder)
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "star.square.fill")
                .font(.title2)
                .foregroundColor(AppColors.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Style Preferences")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
                
                if let style = stylePreferences.primaryStyle {
                    Text(style.displayName)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textSecondary)
                .opacity(isHovered ? 1.0 : 0.5)
        }
    }
    
    @ViewBuilder
    private var primaryColorsSection: some View {
        if !stylePreferences.primaryColors.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Primary Colors")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: 4) {
                    ForEach(Array(stylePreferences.primaryColors.prefix(6).enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    if stylePreferences.primaryColors.count > 6 {
                        Text("+\(stylePreferences.primaryColors.count - 6)")
                            .font(.caption2)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var styleInfluencesSection: some View {
        if !stylePreferences.styleInfluences.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Style Influences")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(stylePreferences.styleInfluences.map { $0.displayName }.joined(separator: ", "))
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
            }
        }
    }
    
    private var additionalDetailsSection: some View {
        HStack(spacing: Spacing.md) {
            formalityView
            seasonView
            colorHarmonyView
        }
    }
    
    @ViewBuilder
    private var formalityView: some View {
        if let formality = stylePreferences.formalityLevel {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(formality.displayName)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
    
    @ViewBuilder
    private var seasonView: some View {
        if let season = stylePreferences.season {
            HStack(spacing: 4) {
                Image(systemName: seasonIcon(for: season))
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(season.displayName)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
    
    @ViewBuilder
    private var colorHarmonyView: some View {
        if let harmony = stylePreferences.colorHarmony {
            HStack(spacing: 4) {
                Image(systemName: "paintpalette")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(harmony.displayName)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
    
    @ViewBuilder
    private var visualThemesSection: some View {
        if !stylePreferences.visualThemes.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(AppColors.primary)
                
                Text("\(stylePreferences.visualThemes.count) visual theme\(stylePreferences.visualThemes.count == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.primary)
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color.gray.opacity(0.05))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(isHovered ? AppColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
    }
    
    private func seasonIcon(for season: WeddingSeason) -> String {
        switch season {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .fall: return "leaf.fill"
        case .winter: return "snowflake"
        }
    }
    
    private var accessibilityDescription: String {
        var description = ""
        
        if let style = stylePreferences.primaryStyle {
            description += "Primary style: \(style.displayName). "
        }
        
        if !stylePreferences.primaryColors.isEmpty {
            description += "\(stylePreferences.primaryColors.count) primary colors. "
        }
        
        if !stylePreferences.styleInfluences.isEmpty {
            description += "Influenced by \(stylePreferences.styleInfluences.map { $0.displayName }.joined(separator: ", ")). "
        }
        
        if let formality = stylePreferences.formalityLevel {
            description += "Formality: \(formality.displayName). "
        }
        
        return description
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StylePreferencesSearchResultCard(
            stylePreferences: StylePreferences(tenantId: "preview"),
            onTap: {}
        )
        
        StylePreferencesSearchResultCard(
            stylePreferences: {
                var prefs = StylePreferences(tenantId: "preview")
                prefs.primaryStyle = .romantic
                prefs.styleInfluences = [.romantic, .vintage]
                prefs.formalityLevel = .semiformal
                prefs.season = .spring
                prefs.primaryColors = [.pink, .white, .gold, .dustyRose]
                prefs.colorHarmony = .analogous
                prefs.visualThemes = [
                    VisualTheme(
                        name: "Ethereal Romance",
                        description: "Soft and dreamy",
                        primaryColor: .white,
                        secondaryColor: .pink,
                        accentColor: .gold,
                        associatedTextures: [.chiffon, .tulle],
                        moodKeywords: ["dreamy", "soft"]
                    )
                ]
                return prefs
            }(),
            onTap: {}
        )
    }
    .padding()
    .frame(width: 400)
}
