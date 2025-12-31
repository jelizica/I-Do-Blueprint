//
//  PhoneNumberTextFieldWrapper.swift
//  I Do Blueprint
//
//  SwiftUI wrapper for phone number input with real-time formatting
//  Uses PhoneNumberKit for validation and formatting
//

import SwiftUI
import PhoneNumberKit
import AppKit

/// SwiftUI wrapper for phone number input with real-time formatting
///
/// Provides phone number formatting using PhoneNumberKit's AsYouTypeFormatter
/// for macOS using NSViewRepresentable.
///
/// ## Features
/// - Real-time formatting as user types
/// - Validation using PhoneNumberKit
/// - Matches app design system
/// - Accessibility support
///
/// ## Usage
/// ```swift
/// struct AddGuestView: View {
///     @State private var phone = ""
///
///     var body: some View {
///         PhoneNumberTextFieldWrapper(
///             phoneNumber: $phone,
///             defaultRegion: "US"
///         )
///         .frame(height: 40)
///     }
/// }
/// ```
struct PhoneNumberTextFieldWrapper: NSViewRepresentable {
    
    // MARK: - Properties
    
    /// Binding to the phone number string
    @Binding var phoneNumber: String
    
    /// Default region code (ISO country code, e.g., "US", "GB", "FR")
    let defaultRegion: String
    
    /// Placeholder text when field is empty
    var placeholder: String = "Phone Number"
    
    /// Whether the field is enabled
    var isEnabled: Bool = true
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        
        // Configure appearance to match design system
        textField.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        textField.textColor = NSColor.labelColor
        textField.backgroundColor = NSColor.controlBackgroundColor
        
        // Set placeholder
        textField.placeholderString = placeholder
        
        // Configure border and styling
        textField.isBordered = true
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        
        // Set enabled state
        textField.isEnabled = isEnabled
        
        // Set up delegate for value changes
        textField.delegate = context.coordinator
        
        // Set initial value
        textField.stringValue = phoneNumber
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Update text if it changed externally
        if nsView.stringValue != phoneNumber {
            nsView.stringValue = phoneNumber
        }
        
        // Update enabled state
        nsView.isEnabled = isEnabled
        
        // Update placeholder
        nsView.placeholderString = placeholder
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(phoneNumber: $phoneNumber, defaultRegion: defaultRegion)
    }
    
    // MARK: - Coordinator
    
    /// Coordinator to handle text field delegate callbacks and formatting
    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var phoneNumber: String
        let defaultRegion: String
        private let formatter: PartialFormatter
        
        init(phoneNumber: Binding<String>, defaultRegion: String) {
            _phoneNumber = phoneNumber
            self.defaultRegion = defaultRegion
            self.formatter = PartialFormatter(defaultRegion: defaultRegion)
        }
        
        /// Called when text changes
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            let currentText = textField.stringValue
            
            // Format the phone number as user types
            let formattedText = formatter.formatPartial(currentText)
            
            // Update the text field with formatted text
            if formattedText != currentText {
                textField.stringValue = formattedText
            }
            
            // Update binding
            phoneNumber = formattedText
        }
        
        /// Called when editing ends
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            phoneNumber = textField.stringValue
        }
    }
}

// MARK: - View Modifiers

extension PhoneNumberTextFieldWrapper {
    
    /// Set the placeholder text
    func placeholder(_ text: String) -> PhoneNumberTextFieldWrapper {
        var view = self
        view.placeholder = text
        return view
    }
    
    /// Set the enabled state
    func disabled(_ disabled: Bool) -> PhoneNumberTextFieldWrapper {
        var view = self
        view.isEnabled = !disabled
        return view
    }
}

// MARK: - Helper Extensions

extension PhoneNumberTextFieldWrapper {
    
    /// Create a phone number field with custom styling
    static func styled(
        phoneNumber: Binding<String>,
        defaultRegion: String = "US",
        placeholder: String = "Phone Number"
    ) -> some View {
        PhoneNumberTextFieldWrapper(
            phoneNumber: phoneNumber,
            defaultRegion: defaultRegion,
            placeholder: placeholder
        )
        .frame(height: 40)
    }
}

// MARK: - Preview

#Preview("Default Configuration") {
    VStack(spacing: Spacing.lg) {
        Text("Phone Number Input")
            .font(Typography.heading)
        
        PhoneNumberTextFieldWrapper(
            phoneNumber: .constant(""),
            defaultRegion: "US"
        )
        .frame(height: 40)
        
        Text("Type a phone number to see real-time formatting")
            .font(Typography.caption)
            .foregroundColor(AppColors.textSecondary)
    }
    .padding(Spacing.xl)
    .frame(width: 400)
}

#Preview("With Existing Number") {
    VStack(spacing: Spacing.lg) {
        Text("Edit Phone Number")
            .font(Typography.heading)
        
        PhoneNumberTextFieldWrapper(
            phoneNumber: .constant("5551234567"),
            defaultRegion: "US"
        )
        .frame(height: 40)
        
        Text("Number is automatically formatted")
            .font(Typography.caption)
            .foregroundColor(AppColors.textSecondary)
    }
    .padding(Spacing.xl)
    .frame(width: 400)
}

#Preview("International Numbers") {
    VStack(spacing: Spacing.lg) {
        Text("International Phone Numbers")
            .font(Typography.heading)
        
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("United States")
                .font(Typography.caption)
            PhoneNumberTextFieldWrapper(
                phoneNumber: .constant(""),
                defaultRegion: "US"
            )
            .frame(height: 40)
            
            Text("United Kingdom")
                .font(Typography.caption)
            PhoneNumberTextFieldWrapper(
                phoneNumber: .constant(""),
                defaultRegion: "GB"
            )
            .frame(height: 40)
            
            Text("France")
                .font(Typography.caption)
            PhoneNumberTextFieldWrapper(
                phoneNumber: .constant(""),
                defaultRegion: "FR"
            )
            .frame(height: 40)
        }
    }
    .padding(Spacing.xl)
    .frame(width: 400)
}

#Preview("Form Integration") {
    Form {
        Section("Contact Information") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Phone Number")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                PhoneNumberTextFieldWrapper(
                    phoneNumber: .constant(""),
                    defaultRegion: "US"
                )
                .frame(height: 40)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Alternative Phone")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                PhoneNumberTextFieldWrapper(
                    phoneNumber: .constant(""),
                    defaultRegion: "US",
                    placeholder: "Alternative Number"
                )
                .frame(height: 40)
            }
        }
    }
    .padding(Spacing.xl)
    .frame(width: 500, height: 300)
}

#Preview("Disabled State") {
    VStack(spacing: Spacing.lg) {
        Text("Disabled Phone Field")
            .font(Typography.heading)
        
        PhoneNumberTextFieldWrapper(
            phoneNumber: .constant("+1 555-123-4567"),
            defaultRegion: "US"
        )
        .disabled(true)
        .frame(height: 40)
        
        Text("Field is disabled and cannot be edited")
            .font(Typography.caption)
            .foregroundColor(AppColors.textSecondary)
    }
    .padding(Spacing.xl)
    .frame(width: 400)
}
