//
//  ValidatedTextField.swift
//  I Do Blueprint
//
//  Text field with built-in validation support
//

import SwiftUI

/// Text field with built-in validation and error display
struct ValidatedTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let validation: ValidationRule?
    let isRequired: Bool
    let autocorrection: Bool

    @State private var errorMessage: String?
    @State private var hasBeenEdited: Bool = false
    @FocusState private var isFocused: Bool

    init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        validation: ValidationRule? = nil,
        isRequired: Bool = false,
        autocorrection: Bool = true
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.validation = validation
        self.isRequired = isRequired
        self.autocorrection = autocorrection
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label with required indicator
            HStack(spacing: 4) {
                Text(label)
                    .font(Typography.subheading)
                    .foregroundColor(SemanticColors.textPrimary)

                if isRequired {
                    Text("*")
                        .font(Typography.subheading)
                        .foregroundColor(SemanticColors.error)
                }
            }

            // Text field
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(!autocorrection)
                .focused($isFocused)
                .onChange(of: text) { _ in
                    hasBeenEdited = true
                    if hasBeenEdited {
                        validate()
                    }
                }
                .onChange(of: isFocused) { focused in
                    if !focused && hasBeenEdited {
                        validate()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(errorMessage != nil ? SemanticColors.error : Color.clear, lineWidth: 1)
                )

            // Error message
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(Typography.caption)
                }
                .foregroundColor(SemanticColors.error)
                .transition(.opacity)
            }
        }
        .accessibleFormField(
            label: label,
            hint: errorMessage,
            isRequired: isRequired
        )
    }

    private func validate() {
        guard let validation = validation else {
            errorMessage = nil
            return
        }

        let result = validation.validate(text)
        withAnimation(AnimationStyle.fast) {
            errorMessage = result.errorMessage
        }
    }

    /// Public method to trigger validation
    func performValidation() -> Bool {
        validate()
        return errorMessage == nil
    }
}

// MARK: - Validated Text Editor

/// Multi-line text editor with validation support
struct ValidatedTextEditor: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let validation: ValidationRule?
    let isRequired: Bool
    let minHeight: CGFloat

    @State private var errorMessage: String?
    @State private var hasBeenEdited: Bool = false
    @FocusState private var isFocused: Bool

    init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        validation: ValidationRule? = nil,
        isRequired: Bool = false,
        minHeight: CGFloat = 100
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.validation = validation
        self.isRequired = isRequired
        self.minHeight = minHeight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label with required indicator
            HStack(spacing: 4) {
                Text(label)
                    .font(Typography.subheading)
                    .foregroundColor(SemanticColors.textPrimary)

                if isRequired {
                    Text("*")
                        .font(Typography.subheading)
                        .foregroundColor(SemanticColors.error)
                }
            }

            // Text editor with placeholder
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textTertiary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.sm)
                }

                TextEditor(text: $text)
                    .font(Typography.bodyRegular)
                    .focused($isFocused)
                    .frame(minHeight: minHeight)
                    .onChange(of: text) { _ in
                        hasBeenEdited = true
                        if hasBeenEdited {
                            validate()
                        }
                    }
                    .onChange(of: isFocused) { focused in
                        if !focused && hasBeenEdited {
                            validate()
                        }
                    }
            }
            .padding(Spacing.xs)
            .background(SemanticColors.contentBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(errorMessage != nil ? SemanticColors.error : SemanticColors.borderPrimary, lineWidth: 1)
            )

            // Error message
            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(Typography.caption)
                }
                .foregroundColor(SemanticColors.error)
                .transition(.opacity)
            }
        }
        .accessibleFormField(
            label: label,
            hint: errorMessage,
            isRequired: isRequired
        )
    }

    private func validate() {
        guard let validation = validation else {
            errorMessage = nil
            return
        }

        let result = validation.validate(text)
        withAnimation(AnimationStyle.fast) {
            errorMessage = result.errorMessage
        }
    }
}

// MARK: - Previews

#Preview("Required Text Field") {
    @Previewable @State var text = ""

    ValidatedTextField(
        label: "Name",
        text: $text,
        placeholder: "Enter your name",
        validation: .requiredName,
        isRequired: true
    )
    .padding()
}

#Preview("Email Field") {
    @Previewable @State var email = ""

    ValidatedTextField(
        label: "Email",
        text: $email,
        placeholder: "email@example.com",
        validation: .requiredEmail,
        isRequired: true,
        autocorrection: false
    )
    .padding()
}

#Preview("Phone Field") {
    @Previewable @State var phone = ""

    ValidatedTextField(
        label: "Phone",
        text: $phone,
        placeholder: "(555) 123-4567",
        validation: .requiredPhone,
        isRequired: true
    )
    .padding()
}

#Preview("Text Editor") {
    @Previewable @State var notes = ""

    ValidatedTextEditor(
        label: "Notes",
        text: $notes,
        placeholder: "Enter your notes here...",
        validation: RequiredRule(fieldName: "Notes"),
        isRequired: true,
        minHeight: 150
    )
    .padding()
}

#Preview("Form with Multiple Fields") {
    @Previewable @State var name = ""
    @Previewable @State var email = ""
    @Previewable @State var phone = ""
    @Previewable @State var notes = ""

    Form {
        Section("Contact Information") {
            ValidatedTextField(
                label: "Name",
                text: $name,
                placeholder: "Enter name",
                validation: .requiredName,
                isRequired: true
            )

            ValidatedTextField(
                label: "Email",
                text: $email,
                placeholder: "email@example.com",
                validation: .requiredEmail,
                isRequired: true,
                autocorrection: false
            )

            ValidatedTextField(
                label: "Phone",
                text: $phone,
                placeholder: "(555) 123-4567",
                validation: PhoneRule()
            )
        }

        Section("Additional Information") {
            ValidatedTextEditor(
                label: "Notes",
                text: $notes,
                placeholder: "Enter any additional notes...",
                minHeight: 100
            )
        }
    }
    .formStyle(.grouped)
}
