//
//  AddGuestViewV2.swift
//  I Do Blueprint
//
//  Glassmorphic Add Guest modal matching HTML design aesthetics
//  Uses design system colors with glassmorphism effects
//

import SwiftUI
import PhoneNumberKit

struct AddGuestViewV2: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Proportional Modal Sizing Pattern
    private let minWidth: CGFloat = 580
    private let maxWidth: CGFloat = 720
    private let minHeight: CGFloat = 580
    private let maxHeight: CGFloat = 680
    private let windowChromeBuffer: CGFloat = 40
    private let widthProportion: CGFloat = 0.55
    private let heightProportion: CGFloat = 0.78
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var relationshipToCouple = ""
    @State private var invitedBy: InvitedBy = .both
    @State private var rsvpStatus: RSVPStatus = .pending
    @State private var plusOneAllowed = true
    @State private var plusOneName = ""
    @State private var attendingCeremony = true
    @State private var attendingReception = true
    @State private var dietaryRestrictions = ""
    @State private var accessibilityNeeds = ""
    @State private var mealOption = ""
    @State private var notes = ""
    @State private var preferredContactMethod: PreferredContactMethod = .email
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = "USA"
    @State private var invitationNumber: String?
    @State private var isWeddingParty = false
    @State private var weddingPartyRole = ""
    @State private var gettingReady = false
    @State private var hairDone = false
    @State private var makeupDone = false
    @State private var selectedTab = 0
    @FocusState private var focusedField: FocusedField?

    let onSave: (Guest) async -> Void

    enum FocusedField: Hashable {
        case firstName, lastName, relationship, plusOneName
    }

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.001)
                .ignoresSafeArea()
            
            modalContent
        }
        .alert("Cannot Save Guest", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(errorMessage)
        }
    }

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion - windowChromeBuffer
        let finalWidth = min(maxWidth, max(minWidth, targetWidth))
        let finalHeight = min(maxHeight, max(minHeight, targetHeight))
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
    private var modalContent: some View {
        VStack(spacing: 0) {
            // Header with title and tabs
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Add Guest")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                
                // Tab pills
                HStack(spacing: 0) {
                    ForEach(0..<4) { index in
                        let titles = ["Basic", "Contact", "Preferences", "Additional"]
                        Button(action: { selectedTab = index }) {
                            Text(titles[index])
                                .font(.system(size: 14, weight: selectedTab == index ? .semibold : .medium))
                                .foregroundColor(selectedTab == index ? Color(red: 0.25, green: 0.25, blue: 0.3) : Color.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Group {
                                        if selectedTab == index {
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 1.0, green: 0.96, blue: 0.96),
                                                            Color(red: 0.95, green: 0.88, blue: 0.85)
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.4))
                )
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.md)
            
            // Content area
            Group {
                switch selectedTab {
                case 0:
                    basicTabContent
                case 1:
                    contactTabContent
                case 2:
                    preferencesTabContent
                case 3:
                    additionalTabContent
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer(minLength: Spacing.md)
            
            // Footer with buttons
            HStack(spacing: Spacing.md) {
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.gray)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.6))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                    )
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                
                Button("Save") { Task { await saveGuest() } }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.55, blue: 0.65),
                                        Color(red: 0.75, green: 0.55, blue: 0.55)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(red: 0.95, green: 0.55, blue: 0.65).opacity(0.4), radius: 8, y: 4)
                    )
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValidForm)
                    .opacity(isValidForm ? 1.0 : 0.6)
            }
            .padding(Spacing.xl)
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.45))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
    }
    
    // MARK: - Basic Tab Content
    
    private var basicTabContent: some View {
        VStack(spacing: Spacing.md) {
            // Row 1: Two columns with equal heights
            HStack(alignment: .top, spacing: Spacing.md) {
                // Personal Information Card (pink tint)
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Personal Information")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                    
                    VStack(spacing: Spacing.sm) {
                        GlassInputField(
                            label: "First Name",
                            text: $firstName,
                            isRequired: true,
                            isFocused: focusedField == .firstName
                        )
                        .focused($focusedField, equals: .firstName)
                        
                        GlassInputField(
                            label: "Last Name",
                            text: $lastName,
                            isRequired: true,
                            isFocused: focusedField == .lastName
                        )
                        .focused($focusedField, equals: .lastName)
                        
                        GlassInputField(
                            label: "Relationship to Couple",
                            text: $relationshipToCouple,
                            isFocused: focusedField == .relationship
                        )
                        .focused($focusedField, equals: .relationship)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.95, blue: 0.95).opacity(0.7),
                                    Color(red: 0.98, green: 0.92, blue: 0.90).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                )
                
                // Attendance Card (green tint)
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Attendance")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                    
                    VStack(spacing: Spacing.md) {
                        ColoredToggleRow(label: "Attending Ceremony", isOn: $attendingCeremony)
                        ColoredToggleRow(label: "Attending Reception", isOn: $attendingReception)
                        ColoredToggleRow(label: "Plus One Allowed", isOn: $plusOneAllowed)
                        
                        if plusOneAllowed {
                            GlassInputField(
                                label: "Plus One Name",
                                text: $plusOneName,
                                isFocused: focusedField == .plusOneName
                            )
                            .focused($focusedField, equals: .plusOneName)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.98, blue: 0.95).opacity(0.7),
                                    Color(red: 0.88, green: 0.95, blue: 0.92).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            
            // Row 2: Wedding Details (full width, subtle pink/peach tint)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Wedding Details")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                
                HStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invited By")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gray)
                        
                        Menu {
                            ForEach(InvitedBy.allCases, id: \.self) { option in
                                Button(option.displayName(with: settingsStore.settings)) {
                                    invitedBy = option
                                }
                            }
                        } label: {
                            HStack {
                                Text(invitedBy.displayName(with: settingsStore.settings))
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RSVP Status")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gray)
                        
                        Menu {
                            ForEach(RSVPStatus.allCases, id: \.self) { status in
                                Button(status.displayName) {
                                    rsvpStatus = status
                                }
                            }
                        } label: {
                            HStack {
                                Text(rsvpStatus.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.96, blue: 0.94).opacity(0.6),
                                Color(red: 0.97, green: 0.94, blue: 0.92).opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Contact Tab Content
    
    private var contactTabContent: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Left Column: Contact Information Card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with icon
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                    Text("Contact Information")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                }
                
                VStack(spacing: Spacing.sm) {
                    GlassInputField(label: "Email Address", text: $email, placeholder: "sarah.j@example.com", isFocused: false)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone Number")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gray)
                        PhoneNumberTextFieldWrapper(
                            phoneNumber: $phone,
                            defaultRegion: "US",
                            placeholder: "(555) 123-4567"
                        )
                        .frame(height: 38)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preferred Contact Method")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.gray)
                        
                        Menu {
                            ForEach(PreferredContactMethod.allCases, id: \.self) { method in
                                Button(method.displayName) {
                                    preferredContactMethod = method
                                }
                            }
                        } label: {
                            HStack {
                                Text(preferredContactMethod.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
            
            // Right Column: Address Card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with icon
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray)
                    Text("Address")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                }
                
                VStack(spacing: Spacing.sm) {
                    GlassInputField(label: "Address Line 1", text: $addressLine1, placeholder: "123 Wedding Lane", isFocused: false)
                    GlassInputField(label: "Address Line 2", text: $addressLine2, placeholder: "Apt 4B", isOptional: true, isFocused: false)
                    
                    HStack(spacing: Spacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("City")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            TextField("New York", text: $city)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("State")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            TextField("NY", text: $state)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .frame(width: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ZIP")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            TextField("10001", text: $zipCode)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .frame(width: 70)
                    }
                    
                    GlassInputField(label: "Country", text: $country, placeholder: "United States", isFocused: false)
                }
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Preferences Tab Content

    @ViewBuilder
    private var preferencesTabContent: some View {
        VStack(spacing: Spacing.md) {
            weddingPartyCard
            diningAndAccessibilityRow
        }
    }

    @ViewBuilder
    private var weddingPartyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
                // Header with icon and toggle
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.4))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wedding Party")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                            Text("Member of the party?")
                                .font(.system(size: 11))
                                .foregroundColor(Color.gray)
                        }
                    }
                    Spacer()
                    PinkToggle(isOn: $isWeddingParty)
                }
                
                if isWeddingParty {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        // Role field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Role")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                            TextField("E.g. Bridesmaid, Groomsman", text: $weddingPartyRole)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Getting Ready section (aligned with Role text field)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Getting Ready")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
                                Text("Pre-ceremony prep?")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.gray)
                                Spacer()
                                SmallGreenToggle(isOn: $gettingReady)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.92, green: 0.98, blue: 0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(red: 0.7, green: 0.85, blue: 0.75), lineWidth: 1)
                                    )
                            )
                        }
                        .frame(width: 180)
                        .padding(.top, 18)
                        
                        // Hair/Makeup toggles (only shown when Getting Ready is true)
                        if gettingReady {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "scissors")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.gray)
                                    Text("Hair")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.gray)
                                    Spacer()
                                    SmallGrayToggle(isOn: $hairDone)
                                }
                                HStack {
                                    Image(systemName: "paintbrush.pointed")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.gray)
                                    Text("Makeup")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.gray)
                                    Spacer()
                                    SmallGrayToggle(isOn: $makeupDone)
                                }
                            }
                            .frame(width: 100)
                            .padding(.top, 18)
                        }
                    }
                }
            }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var diningAndAccessibilityRow: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            diningPreferencesCard
            accessibilityCard
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var diningPreferencesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
                Text("Dining Preferences")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
            }

            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("Meal Option")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)
                    Spacer()
                    mealOptionMenu
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dietary Restrictions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)
                    TextField("E.g. Nut allergy, lactose intolerant...", text: $dietaryRestrictions)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var mealOptionMenu: some View {
        Menu {
            Button("Standard") { mealOption = "Standard" }
            ForEach(settingsStore.settings.guests.customMealOptions, id: \.self) { option in
                Button(option) { mealOption = option }
            }
        } label: {
            Text(mealOption.isEmpty ? "Standard" : mealOption)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var accessibilityCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            accessibilityCardHeader
            accessibilityTextEditor
            accessibilityCardFooter
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var accessibilityCardHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.roll")
                .font(.system(size: 14))
                .foregroundColor(Color.gray)
            Text("Accessibility")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
        }
    }

    @ViewBuilder
    private var accessibilityTextEditor: some View {
        TextEditor(text: $accessibilityNeeds)
            .font(.system(size: 14))
            .frame(minHeight: 80)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .scrollContentBackground(.hidden)
            .overlay(
                Group {
                    if accessibilityNeeds.isEmpty {
                        Text("Describe any mobility, hearing, or visual assistance needed...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .topLeading
            )
    }

    @ViewBuilder
    private var accessibilityCardFooter: some View {
        Text("Shared with venue coordinator for accommodations.")
            .font(.system(size: 10))
            .foregroundColor(Color.gray)
    }

    // MARK: - Additional Tab Content

    @ViewBuilder
    private var additionalTabContent: some View {
        VStack(spacing: Spacing.md) {
            additionalNotesCard
            futureFeaturesCard
            Spacer()
        }
    }

    @ViewBuilder
    private var additionalNotesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
                Text("Additional Notes")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
            }

            notesTextEditor

            HStack {
                Text("Visible only to admins")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray)
                Spacer()
                Text("\(notes.count)/500 characters")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray)
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var notesTextEditor: some View {
        TextEditor(text: $notes)
            .font(.system(size: 14))
            .frame(minHeight: 100)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .scrollContentBackground(.hidden)
            .overlay(
                Group {
                    if notes.isEmpty {
                        Text("Add any special requirements, memories, or internal notes about this guest...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.gray.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .topLeading
            )
    }

    @ViewBuilder
    private var futureFeaturesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
                Text("Future Features")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.3))
            }

            futureFeaturesContent
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var futureFeaturesContent: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "gift")
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Coming Soon")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
                Text("Gift tracking, table assignment visualization, and other advanced features will be available in future updates.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
                    .lineLimit(2)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
    }

    private var isValidForm: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func saveGuest() async {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            AppLogger.ui.error("Cannot save guest: No couple selected")
            errorMessage = "Please select a couple before adding a guest."
            showingError = true
            return
        }

        let newGuest = Guest(
            id: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            guestGroupId: nil,
            relationshipToCouple: relationshipToCouple.isEmpty ? nil : relationshipToCouple.trimmingCharacters(in: .whitespacesAndNewlines),
            invitedBy: invitedBy,
            rsvpStatus: rsvpStatus,
            rsvpDate: nil,
            plusOneAllowed: plusOneAllowed,
            plusOneName: plusOneName.isEmpty ? nil : plusOneName.trimmingCharacters(in: .whitespacesAndNewlines),
            plusOneAttending: false,
            attendingCeremony: attendingCeremony,
            attendingReception: attendingReception,
            attendingRehearsal: attendingCeremony,
            attendingOtherEvents: nil,
            dietaryRestrictions: dietaryRestrictions.isEmpty ? nil : dietaryRestrictions.trimmingCharacters(in: .whitespacesAndNewlines),
            accessibilityNeeds: accessibilityNeeds.isEmpty ? nil : accessibilityNeeds.trimmingCharacters(in: .whitespacesAndNewlines),
            tableAssignment: nil,
            seatNumber: nil,
            preferredContactMethod: preferredContactMethod,
            addressLine1: addressLine1.isEmpty ? nil : addressLine1.trimmingCharacters(in: .whitespacesAndNewlines),
            addressLine2: addressLine2.isEmpty ? nil : addressLine2.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.isEmpty ? nil : city.trimmingCharacters(in: .whitespacesAndNewlines),
            state: state.isEmpty ? nil : state.trimmingCharacters(in: .whitespacesAndNewlines),
            zipCode: zipCode.isEmpty ? nil : zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.isEmpty ? "USA" : country.trimmingCharacters(in: .whitespacesAndNewlines),
            invitationNumber: invitationNumber,
            isWeddingParty: isWeddingParty,
            weddingPartyRole: weddingPartyRole.isEmpty ? nil : weddingPartyRole.trimmingCharacters(in: .whitespacesAndNewlines),
            preparationNotes: nil,
            coupleId: coupleId,
            mealOption: mealOption.isEmpty ? nil : mealOption.trimmingCharacters(in: .whitespacesAndNewlines),
            giftReceived: false,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            hairDone: false,
            makeupDone: false
        )

        await onSave(newGuest)
        dismiss()
    }
}

// MARK: - Glass Input Field

struct GlassInputField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isRequired: Bool = false
    var isOptional: Bool = false
    var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.gray)
                if isRequired {
                    Text("*")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.5))
                }
                if isOptional {
                    Text("(Optional)")
                        .font(.system(size: 10))
                        .foregroundColor(Color.gray.opacity(0.7))
                }
            }
            
            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isFocused ?
                                Color(red: 1.0, green: 0.95, blue: 0.96) :
                                Color.white.opacity(0.6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isFocused ?
                                        Color(red: 0.95, green: 0.6, blue: 0.7) :
                                        Color.gray.opacity(0.2),
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                        .shadow(
                            color: isFocused ?
                                Color(red: 0.95, green: 0.5, blue: 0.6).opacity(0.3) :
                                Color.clear,
                            radius: isFocused ? 8 : 0
                        )
                )
        }
    }
}

// MARK: - Colored Toggle Row

struct ColoredToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.35))
            
            Spacer()
            
            // Custom colored toggle
            ZStack {
                // Track
                Capsule()
                    .fill(
                        isOn ?
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.75, blue: 0.55),
                                    Color(red: 0.55, green: 0.8, blue: 0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.white, Color.white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .frame(width: 44, height: 24)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
                    .offset(x: isOn ? 10 : -10)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
            }
            .onTapGesture {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Pink Toggle (for Wedding Party)

struct PinkToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    isOn ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.4, blue: 0.5),
                                Color(red: 0.85, green: 0.35, blue: 0.45)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .frame(width: 44, height: 24)
            
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
                .offset(x: isOn ? 10 : -10)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
        }
        .onTapGesture {
            isOn.toggle()
        }
    }
}

// MARK: - Small Green Toggle

struct SmallGreenToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    isOn ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.75, blue: 0.55),
                                Color(red: 0.55, green: 0.8, blue: 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .frame(width: 36, height: 20)
            
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .shadow(color: Color.black.opacity(0.15), radius: 1, y: 1)
                .offset(x: isOn ? 8 : -8)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
        }
        .onTapGesture {
            isOn.toggle()
        }
    }
}

// MARK: - Small Gray Toggle

struct SmallGrayToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    isOn ?
                        Color.gray.opacity(0.5) :
                        Color.gray.opacity(0.2)
                )
                .frame(width: 32, height: 18)
            
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .shadow(color: Color.black.opacity(0.1), radius: 1, y: 1)
                .offset(x: isOn ? 7 : -7)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
        }
        .onTapGesture {
            isOn.toggle()
        }
    }
}

#Preview {
    AddGuestViewV2 { _ in }
        .environmentObject(SettingsStoreV2())
        .environmentObject(AppCoordinator.shared)
}
