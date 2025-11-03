//
//  ObstacleEditorSheet.swift
//  I Do Blueprint
//
//  Sheet view for editing venue obstacles (stage, bar, DJ booth, etc.)
//

import SwiftUI

struct ObstacleEditorSheet: View {
    @Binding var obstacle: VenueObstacle
    let onSave: (VenueObstacle) -> Void
    let onDismiss: () -> Void

    @State private var name: String
    @State private var obstacleType: ObstacleType
    @State private var positionX: String
    @State private var positionY: String
    @State private var width: String
    @State private var height: String
    @State private var isMovable: Bool
    @State private var showValidationError = false
    @State private var validationMessage = ""

    init(
        obstacle: Binding<VenueObstacle>,
        onSave: @escaping (VenueObstacle) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _obstacle = obstacle
        self.onSave = onSave
        self.onDismiss = onDismiss

        // Initialize state from obstacle
        _name = State(initialValue: obstacle.wrappedValue.name)
        _obstacleType = State(initialValue: obstacle.wrappedValue.obstacleType)
        _positionX = State(initialValue: String(format: "%.0f", obstacle.wrappedValue.position.x))
        _positionY = State(initialValue: String(format: "%.0f", obstacle.wrappedValue.position.y))
        _width = State(initialValue: String(format: "%.0f", obstacle.wrappedValue.size.width))
        _height = State(initialValue: String(format: "%.0f", obstacle.wrappedValue.size.height))
        _isMovable = State(initialValue: obstacle.wrappedValue.isMovable)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Venue Element")
                        .font(Typography.title2)
                        .foregroundColor(AppColors.textPrimary)
                        .accessibleHeading(level: 1)

                    Text("Configure obstacle properties")
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                HStack(spacing: Spacing.md) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .accessibleActionButton(
                        label: "Cancel editing",
                        hint: "Discards changes and closes the editor"
                    )

                    Button("Save") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                    .accessibleActionButton(
                        label: "Save obstacle",
                        hint: isValid ? "Saves changes and closes the editor" : "Cannot save: \(validationMessage)"
                    )
                }
            }
            .padding(Spacing.lg)

            Divider()

            HStack(spacing: Spacing.lg) {
                // Left: Properties Form
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            // Properties Card
                            VStack(alignment: .leading, spacing: Spacing.lg) {
                                Text("Properties")
                                    .font(Typography.heading)
                                    .foregroundColor(AppColors.textPrimary)
                                    .accessibleHeading(level: 2)

                                Divider()

                                VStack(alignment: .leading, spacing: Spacing.lg) {
                                    // Name
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Name")
                                            .font(Typography.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.textSecondary)
                                            .textCase(.uppercase)

                                        TextField("Element name", text: $name)
                                            .textFieldStyle(.roundedBorder)
                                            .accessibleFormField(
                                                label: "Obstacle name",
                                                hint: "Enter a descriptive name for this venue element",
                                                isRequired: true
                                            )
                                    }

                                    Divider()

                                    // Type
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Type")
                                            .font(Typography.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.textSecondary)
                                            .textCase(.uppercase)

                                        Picker("Type", selection: $obstacleType) {
                                            ForEach(ObstacleType.allCases, id: \.self) { type in
                                                HStack {
                                                    Image(systemName: type.icon)
                                                    Text(type.displayName)
                                                }
                                                .tag(type)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .accessibleFormField(
                                            label: "Obstacle type",
                                            hint: "Select the type of venue element"
                                        )
                                        .onChange(of: obstacleType) { _, newType in
                                            // Update isMovable based on type
                                            isMovable = newType != .wall && newType != .column
                                        }
                                    }

                                    Divider()

                                    // Position
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Position")
                                            .font(Typography.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.textSecondary)
                                            .textCase(.uppercase)

                                        HStack(spacing: Spacing.md) {
                                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                                Text("X")
                                                    .font(Typography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                                TextField("X", text: $positionX)
                                                    .textFieldStyle(.roundedBorder)
                                                    .frame(width: 100)
                                                    .accessibleFormField(
                                                        label: "X position",
                                                        hint: "Horizontal position in pixels"
                                                    )
                                            }

                                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                                Text("Y")
                                                    .font(Typography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                                TextField("Y", text: $positionY)
                                                    .textFieldStyle(.roundedBorder)
                                                    .frame(width: 100)
                                                    .accessibleFormField(
                                                        label: "Y position",
                                                        hint: "Vertical position in pixels"
                                                    )
                                            }
                                        }
                                    }

                                    Divider()

                                    // Size
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        Text("Size")
                                            .font(Typography.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppColors.textSecondary)
                                            .textCase(.uppercase)

                                        HStack(spacing: Spacing.md) {
                                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                                Text("Width")
                                                    .font(Typography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                                TextField("Width", text: $width)
                                                    .textFieldStyle(.roundedBorder)
                                                    .frame(width: 100)
                                                    .accessibleFormField(
                                                        label: "Width",
                                                        hint: "Width in pixels, must be greater than zero",
                                                        isRequired: true
                                                    )
                                            }

                                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                                Text("Height")
                                                    .font(Typography.caption)
                                                    .foregroundColor(AppColors.textSecondary)
                                                TextField("Height", text: $height)
                                                    .textFieldStyle(.roundedBorder)
                                                    .frame(width: 100)
                                                    .accessibleFormField(
                                                        label: "Height",
                                                        hint: "Height in pixels, must be greater than zero",
                                                        isRequired: true
                                                    )
                                            }
                                        }
                                    }

                                    Divider()

                                    // Movable Toggle
                                    Toggle(isOn: $isMovable) {
                                        VStack(alignment: .leading, spacing: Spacing.xs) {
                                            Text("Movable")
                                                .font(Typography.bodyRegular)
                                                .foregroundColor(AppColors.textPrimary)
                                            Text("Allow this element to be repositioned")
                                                .font(Typography.caption)
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    .disabled(obstacleType == .wall || obstacleType == .column)
                                    .accessibleFormField(
                                        label: "Movable toggle",
                                        hint: obstacleType == .wall || obstacleType == .column
                                            ? "Walls and columns cannot be moved"
                                            : "Toggle whether this element can be repositioned"
                                    )
                                }
                            }
                            .padding(Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.lg)
                                    .fill(AppColors.cardBackground)
                                    .shadow(
                                        color: AppColors.shadowLight,
                                        radius: ShadowStyle.light.radius,
                                        x: 0,
                                        y: 2
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.lg)
                                    .stroke(AppColors.borderLight, lineWidth: 1)
                            )
                        }
                        .padding(Spacing.lg)
                    }
                }
                .frame(width: 320)

                Divider()

                // Right: Preview
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Preview")
                        .font(Typography.heading)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.lg)
                        .accessibleHeading(level: 2)

                    ZStack {
                        // Canvas background
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(AppColors.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )

                        // Preview obstacle
                        if let previewWidth = Double(width),
                           let previewHeight = Double(height),
                           previewWidth > 0,
                           previewHeight > 0 {

                            VStack(spacing: Spacing.sm) {
                                // Obstacle shape
                                RoundedRectangle(cornerRadius: CornerRadius.sm)
                                    .fill(obstacleType.defaultColor.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                                            .stroke(obstacleType.defaultColor, lineWidth: 2)
                                    )
                                    .frame(
                                        width: min(previewWidth * 0.5, 150),
                                        height: min(previewHeight * 0.5, 150)
                                    )
                                    .overlay(
                                        VStack(spacing: Spacing.xs) {
                                            Image(systemName: obstacleType.icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(obstacleType.defaultColor)

                                            Text(name.isEmpty ? "Unnamed" : name)
                                                .font(Typography.caption)
                                                .foregroundColor(AppColors.textPrimary)
                                                .lineLimit(1)
                                        }
                                    )

                                // Dimensions label
                                Text("\(Int(previewWidth)) × \(Int(previewHeight)) px")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        } else {
                            VStack(spacing: Spacing.md) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.textSecondary)

                                Text("Invalid dimensions")
                                    .font(Typography.bodySmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Spacing.lg)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Obstacle preview")
                    .accessibilityValue("Shows how the \(obstacleType.displayName) will appear on the seating chart")

                    // Validation Error
                    if showValidationError {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppColors.error)
                            Text(validationMessage)
                                .font(Typography.bodySmall)
                                .foregroundColor(AppColors.error)
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(AppColors.errorLight)
                        )
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Validation error: \(validationMessage)")
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    // MARK: - Validation

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(width) ?? 0 > 0 &&
        Double(height) ?? 0 > 0 &&
        Double(positionX) != nil &&
        Double(positionY) != nil
    }

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Name is required"
            showValidationError = true
            return false
        }

        guard let widthValue = Double(width), widthValue > 0 else {
            validationMessage = "Width must be greater than zero"
            showValidationError = true
            return false
        }

        guard let heightValue = Double(height), heightValue > 0 else {
            validationMessage = "Height must be greater than zero"
            showValidationError = true
            return false
        }

        guard Double(positionX) != nil else {
            validationMessage = "Invalid X position"
            showValidationError = true
            return false
        }

        guard Double(positionY) != nil else {
            validationMessage = "Invalid Y position"
            showValidationError = true
            return false
        }

        showValidationError = false
        return true
    }

    // MARK: - Actions

    private func saveChanges() {
        guard validate() else { return }

        var updatedObstacle = obstacle
        updatedObstacle.name = name.trimmingCharacters(in: .whitespaces)
        updatedObstacle.obstacleType = obstacleType
        updatedObstacle.position = CGPoint(
            x: Double(positionX) ?? 0,
            y: Double(positionY) ?? 0
        )
        updatedObstacle.size = CGSize(
            width: Double(width) ?? 0,
            height: Double(height) ?? 0
        )
        updatedObstacle.isMovable = isMovable

        onSave(updatedObstacle)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var obstacle = VenueObstacle(
        name: "Main Bar",
        position: CGPoint(x: 100, y: 100),
        size: CGSize(width: 200, height: 80),
        type: .bar
    )

    return ObstacleEditorSheet(
        obstacle: $obstacle,
        onSave: { _ in },
        onDismiss: { }
    )
}
