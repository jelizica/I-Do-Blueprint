//
//  ThemeSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2

    // Local state for color pickers (SwiftUI ColorPicker works with Color, not hex strings)
    @State private var weddingColor1: Color = .purple.opacity(0.3)
    @State private var weddingColor2: Color = Color.fromHex("5A9070")
    @State private var hexInput1: String = ""
    @State private var hexInput2: String = ""
    @State private var showHexInput: Bool = true  // Show by default, can be hidden

    // Computed properties for dynamic preview
    private var previewWeddingTitle: String {
        let partner1 = viewModel.settings.global.partner1Nickname.isEmpty
            ? viewModel.settings.global.partner1FullName
            : viewModel.settings.global.partner1Nickname
        let partner2 = viewModel.settings.global.partner2Nickname.isEmpty
            ? viewModel.settings.global.partner2FullName
            : viewModel.settings.global.partner2Nickname

        if !partner1.isEmpty && !partner2.isEmpty {
            return "\(partner1) & \(partner2)'s Wedding"
        } else if !partner1.isEmpty {
            return "\(partner1)'s Wedding"
        } else if !partner2.isEmpty {
            return "\(partner2)'s Wedding"
        } else {
            return "Your Wedding"
        }
    }

    private var previewWeddingDate: String? {
        let dateString = viewModel.settings.global.weddingDate
        guard !dateString.isEmpty,
              let date = DateFormatting.parseDateFromDatabase(dateString) else {
            return nil
        }
        let timezone = DateFormatting.userTimeZone(from: viewModel.settings)
        return DateFormatting.formatDateLong(date, timezone: timezone)
    }

    private var previewDaysUntil: Int {
        let dateString = viewModel.settings.global.weddingDate
        guard !dateString.isEmpty,
              let weddingDate = DateFormatting.parseDateFromDatabase(dateString) else {
            return 220  // Fallback
        }
        let timezone = DateFormatting.userTimeZone(from: viewModel.settings)
        return DateFormatting.daysBetween(from: Date(), to: weddingDate, in: timezone)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Theme",
                subtitle: "Appearance and color preferences",
                sectionName: "theme",
                isSaving: viewModel.savingSections.contains("theme"),
                hasUnsavedChanges: viewModel.localSettings.theme != viewModel.settings.theme,
                onSave: {
                    Task {
                        await viewModel.saveThemeSettings()
                    }
                })

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Banner Color Source Toggle
                SettingsRow(label: "Dashboard Banner Colors") {
                    Picker("Color Source", selection: $viewModel.localSettings.theme.useCustomWeddingColors) {
                        Text("Use Theme Colors").tag(false)
                        Text("Use Custom Wedding Colors").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }

                // MARK: - Theme Color Scheme (shown when using theme colors)
                if !viewModel.localSettings.theme.useCustomWeddingColors {
                    SettingsRow(label: "Color Scheme") {
                        Picker("Color Scheme", selection: $viewModel.localSettings.theme.colorScheme) {
                            Text("Blush Romance (Default)").tag("blush-romance")
                            Text("Sage Serenity").tag("sage-serenity")
                            Text("Lavender Dream").tag("lavender-dream")
                            Text("Terracotta Warm").tag("terracotta-warm")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 250)
                    }

                    // Theme preview
                    themePreviewCard
                        .id(viewModel.localSettings.theme.colorScheme) // Force update when scheme changes
                }

                // MARK: - Custom Wedding Colors (shown when using custom colors)
                if viewModel.localSettings.theme.useCustomWeddingColors {
                    customWeddingColorsSection
                }

                Divider()
                    .padding(.vertical, Spacing.sm)

                SettingsRow(label: "Dark Mode") {
                    Toggle("", isOn: $viewModel.localSettings.theme.darkMode)
                        .labelsHidden()
                }
            }
        }
        .onAppear {
            // Initialize color picker states from saved settings
            weddingColor1 = Color.fromHex(viewModel.localSettings.theme.weddingColor1.replacingOccurrences(of: "#", with: ""))
            weddingColor2 = Color.fromHex(viewModel.localSettings.theme.weddingColor2.replacingOccurrences(of: "#", with: ""))
            hexInput1 = viewModel.localSettings.theme.weddingColor1
            hexInput2 = viewModel.localSettings.theme.weddingColor2
        }
    }

    // MARK: - Theme Preview Card

    private var themePreviewCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Preview")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppGradients.themeGradient(for: viewModel.localSettings.theme.colorScheme))
                    .frame(height: 100)

                HStack(spacing: Spacing.lg) {
                    // Left side - Wedding info
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(previewWeddingTitle)
                            .font(Typography.title3)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        if let dateText = previewWeddingDate {
                            Text(dateText)
                                .font(Typography.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    // Right side - Days count
                    VStack(spacing: 2) {
                        Text("\(previewDaysUntil)")
                            .font(Typography.numberLarge)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                        Text("DAYS UNTIL")
                            .font(Typography.caption2)
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(1.0)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.2))
                    )
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.leading, 120) // Align with other settings content
    }

    // MARK: - Custom Wedding Colors Section

    private var customWeddingColorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Wedding Colors")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textPrimary)

            HStack(spacing: Spacing.xl) {
                // Color 1
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Color 1 (Left)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    HStack(spacing: Spacing.sm) {
                        ColorPicker("", selection: $weddingColor1, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 44, height: 44)
                            .onChange(of: weddingColor1) { _, newColor in
                                let hex = newColor.toHex()
                                viewModel.localSettings.theme.weddingColor1 = hex
                                hexInput1 = hex
                            }

                        if showHexInput {
                            TextField("#RRGGBB", text: $hexInput1)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .onChange(of: hexInput1) { _, newValue in
                                    let cleaned = newValue.replacingOccurrences(of: "#", with: "")
                                    if cleaned.count == 6, cleaned.allSatisfy({ $0.isHexDigit }) {
                                        weddingColor1 = Color.fromHex(cleaned)
                                        viewModel.localSettings.theme.weddingColor1 = "#\(cleaned.uppercased())"
                                    }
                                }
                        }
                    }
                }

                // Color 2
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Color 2 (Right)")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    HStack(spacing: Spacing.sm) {
                        ColorPicker("", selection: $weddingColor2, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 44, height: 44)
                            .onChange(of: weddingColor2) { _, newColor in
                                let hex = newColor.toHex()
                                viewModel.localSettings.theme.weddingColor2 = hex
                                hexInput2 = hex
                            }

                        if showHexInput {
                            TextField("#RRGGBB", text: $hexInput2)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .onChange(of: hexInput2) { _, newValue in
                                    let cleaned = newValue.replacingOccurrences(of: "#", with: "")
                                    if cleaned.count == 6, cleaned.allSatisfy({ $0.isHexDigit }) {
                                        weddingColor2 = Color.fromHex(cleaned)
                                        viewModel.localSettings.theme.weddingColor2 = "#\(cleaned.uppercased())"
                                    }
                                }
                        }
                    }
                }

                Spacer()

                // Toggle hex input
                Button(action: { showHexInput.toggle() }) {
                    Label(
                        showHexInput ? "Hide Hex" : "Enter Hex Code",
                        systemImage: showHexInput ? "eye.slash" : "number"
                    )
                    .font(Typography.caption)
                }
                .buttonStyle(.borderless)
            }

            // Custom colors preview
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Preview")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [weddingColor1, weddingColor2],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)

                    HStack(spacing: Spacing.lg) {
                        // Left side - Wedding info
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(previewWeddingTitle)
                                .font(Typography.title3)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                            if let dateText = previewWeddingDate {
                                Text(dateText)
                                    .font(Typography.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        // Right side - Days count
                        VStack(spacing: 2) {
                            Text("\(previewDaysUntil)")
                                .font(Typography.numberLarge)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                            Text("DAYS UNTIL")
                                .font(Typography.caption2)
                                .foregroundColor(.white.opacity(0.9))
                                .tracking(1.0)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.2))
                        )
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }

            // Helpful tip
            HStack(spacing: Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(SemanticColors.warning)
                    .font(.system(size: 12))
                Text("Tip: Choose colors that match your wedding theme or invitations!")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(.leading, 120) // Align with other settings content
    }
}

#Preview {
    ThemeSettingsView(viewModel: SettingsStoreV2())
        .padding()
}
