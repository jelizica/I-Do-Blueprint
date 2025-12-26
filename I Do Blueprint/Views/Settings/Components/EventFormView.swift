//
//  EventFormView.swift
//  I Do Blueprint
//
//  Form for creating and editing wedding events
//

import SwiftUI

enum EventFormMode {
    case create
    case edit(WeddingEvent)
    
    var title: String {
        switch self {
        case .create: return "Add Wedding Event"
        case .edit: return "Edit Wedding Event"
        }
    }
    
    var submitButtonTitle: String {
        switch self {
        case .create: return "Create Event"
        case .edit: return "Save Changes"
        }
    }
}

struct EventFormView: View {
    let mode: EventFormMode
    let onSave: (WeddingEvent) -> Void
    let onCancel: () -> Void
    
    @State private var eventName: String = ""
    @State private var eventType: String = "ceremony"
    @State private var eventDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var hasStartTime: Bool = false
    @State private var hasEndTime: Bool = false
    @State private var venueName: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var guestCount: String = ""
    @State private var budgetAllocated: String = ""
    @State private var notes: String = ""
    @State private var description: String = ""
    @State private var isMainEvent: Bool = false
    @State private var isConfirmed: Bool = false
    @State private var eventOrder: String = "1"
    
    // Validation state
    @State private var guestCountError: String?
    @State private var budgetAllocatedError: String?
    @State private var eventOrderError: String?
    
    // Error state for save failures
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private let eventTypes = [
        "ceremony",
        "reception",
        "rehearsal",
        "brunch",
        "bachelor_party",
        "bachelorette_party",
        "engagement_party",
        "other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Event Details") {
                    TextField("Event Name", text: $eventName)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach(eventTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                    
                    Toggle("Main Event", isOn: $isMainEvent)
                    
                    Toggle("Confirmed", isOn: $isConfirmed)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Display Order", text: $eventOrder)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: eventOrder) { _, newValue in
                                validateEventOrder(newValue)
                            }
                        
                        if let error = eventOrderError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Time Information
                Section("Time") {
                    Toggle("Has Start Time", isOn: $hasStartTime)
                    
                    if hasStartTime {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Toggle("Has End Time", isOn: $hasEndTime)
                    
                    if hasEndTime {
                        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                // Venue Information
                Section("Venue") {
                    TextField("Venue Name", text: $venueName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Address", text: $address)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        TextField("City", text: $city)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("State", text: $state)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        
                        TextField("ZIP", text: $zipCode)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                }
                
                // Additional Details
                Section("Additional Information") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Expected Guest Count", text: $guestCount)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: guestCount) { _, newValue in
                                validateGuestCount(newValue)
                            }
                        
                        if let error = guestCountError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Budget Allocated", text: $budgetAllocated)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: budgetAllocated) { _, newValue in
                                validateBudgetAllocated(newValue)
                            }
                        
                        if let error = budgetAllocatedError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(mode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.submitButtonTitle) {
                        saveEvent()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 600, height: 700)
        .alert("Error Saving Event", isPresented: $showError) {
            Button("OK", role: .cancel) {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadEventData()
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        let hasValidName = !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasValidType = !eventType.isEmpty
        let hasNoNumericErrors = guestCountError == nil && budgetAllocatedError == nil && eventOrderError == nil
        
        return hasValidName && hasValidType && hasNoNumericErrors
    }
    
    private func validateGuestCount(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty is valid (optional field)
        if trimmed.isEmpty {
            guestCountError = nil
            return
        }
        
        // Check if it's a valid integer
        guard let count = Int(trimmed), count >= 0 else {
            guestCountError = "Please enter a valid non-negative number"
            return
        }
        
        // Valid
        guestCountError = nil
    }
    
    private func validateBudgetAllocated(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty is valid (optional field)
        if trimmed.isEmpty {
            budgetAllocatedError = nil
            return
        }
        
        // Check if it's a valid double
        guard let budget = Double(trimmed), budget >= 0 else {
            budgetAllocatedError = "Please enter a valid non-negative amount"
            return
        }
        
        // Valid
        budgetAllocatedError = nil
    }
    
    private func validateEventOrder(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty is valid (will default to nil)
        if trimmed.isEmpty {
            eventOrderError = nil
            return
        }
        
        // Check if it's a valid integer
        guard let order = Int(trimmed), order > 0 else {
            eventOrderError = "Please enter a valid positive number"
            return
        }
        
        // Valid
        eventOrderError = nil
    }
    
    // MARK: - Data Loading
    
    private func loadEventData() {
        guard case .edit(let event) = mode else { return }
        
        eventName = event.eventName
        eventType = event.eventType
        eventDate = event.eventDate
        
        if let start = event.startTime {
            hasStartTime = true
            startTime = start
        }
        
        if let end = event.endTime {
            hasEndTime = true
            endTime = end
        }
        
        venueName = event.venueName ?? ""
        address = event.address ?? ""
        city = event.city ?? ""
        state = event.state ?? ""
        zipCode = event.zipCode ?? ""
        guestCount = event.guestCount.map { String($0) } ?? ""
        budgetAllocated = event.budgetAllocated.map { String(format: "%.2f", $0) } ?? ""
        notes = event.notes ?? ""
        description = event.description ?? ""
        isMainEvent = event.isMainEvent ?? false
        isConfirmed = event.isConfirmed ?? false
        eventOrder = event.eventOrder.map { String($0) } ?? "1"
    }
    
    // MARK: - Save Event
    
    private func saveEvent() {
        guard let tenantId = SessionManager.shared.currentTenantId else {
            // Log the error
            AppLogger.ui.error("Failed to save event: No tenant ID available. User may not be signed in or couple not selected.")
            
            // Show user-facing error
            errorMessage = "Unable to save event. Please ensure you are signed in and have selected a couple profile. If the problem persists, try signing out and signing back in."
            showError = true
            return
        }
        
        // Safely parse numeric values
        let parsedGuestCount: Int?
        if !guestCount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let count = Int(guestCount.trimmingCharacters(in: .whitespacesAndNewlines)), count >= 0 else {
                // This shouldn't happen due to validation, but handle gracefully
                guestCountError = "Please enter a valid non-negative number"
                return
            }
            parsedGuestCount = count
        } else {
            parsedGuestCount = nil
        }
        
        let parsedBudgetAllocated: Double?
        if !budgetAllocated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let budget = Double(budgetAllocated.trimmingCharacters(in: .whitespacesAndNewlines)), budget >= 0 else {
                // This shouldn't happen due to validation, but handle gracefully
                budgetAllocatedError = "Please enter a valid non-negative amount"
                return
            }
            parsedBudgetAllocated = budget
        } else {
            parsedBudgetAllocated = nil
        }
        
        let parsedEventOrder: Int?
        if !eventOrder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let order = Int(eventOrder.trimmingCharacters(in: .whitespacesAndNewlines)), order > 0 else {
                // This shouldn't happen due to validation, but handle gracefully
                eventOrderError = "Please enter a valid positive number"
                return
            }
            parsedEventOrder = order
        } else {
            parsedEventOrder = nil
        }
        
        let eventId: String
        switch mode {
        case .create:
            eventId = UUID().uuidString
        case .edit(let event):
            eventId = event.id
        }
        
        let event = WeddingEventDB(
            id: eventId,
            eventName: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
            eventType: eventType,
            eventDate: eventDate,
            startTime: hasStartTime ? startTime : nil,
            endTime: hasEndTime ? endTime : nil,
            venueId: nil,
            venueName: venueName.isEmpty ? nil : venueName,
            address: address.isEmpty ? nil : address,
            city: city.isEmpty ? nil : city,
            state: state.isEmpty ? nil : state,
            zipCode: zipCode.isEmpty ? nil : zipCode,
            guestCount: parsedGuestCount,
            budgetAllocated: parsedBudgetAllocated,
            notes: notes.isEmpty ? nil : notes,
            isConfirmed: isConfirmed,
            description: description.isEmpty ? nil : description,
            eventOrder: parsedEventOrder,
            isMainEvent: isMainEvent,
            venueLocation: nil,
            eventTime: hasStartTime ? startTime : nil,
            coupleId: tenantId.uuidString,
            createdAt: nil,
            updatedAt: nil
        )
        
        onSave(event)
    }
}

#Preview("Create Mode") {
    EventFormView(
        mode: .create,
        onSave: { _ in },
        onCancel: { }
    )
}

#Preview("Edit Mode") {
    let sampleEvent = WeddingEventDB(
        id: UUID().uuidString,
        eventName: "Wedding Ceremony",
        eventType: "ceremony",
        eventDate: Date(),
        startTime: Date(),
        endTime: nil,
        venueId: nil,
        venueName: "Beautiful Gardens",
        address: "123 Main St",
        city: "San Francisco",
        state: "CA",
        zipCode: "94102",
        guestCount: 150,
        budgetAllocated: 5000.0,
        notes: "Outdoor ceremony",
        isConfirmed: true,
        description: "Main wedding ceremony",
        eventOrder: 1,
        isMainEvent: true,
        venueLocation: nil,
        eventTime: nil,
        coupleId: UUID().uuidString,
        createdAt: nil,
        updatedAt: nil
    )
    
    EventFormView(
        mode: .edit(sampleEvent),
        onSave: { _ in },
        onCancel: { }
    )
}
