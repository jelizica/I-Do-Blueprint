import SwiftUI

struct AddBudgetCategoryView: View {
    private let logger = AppLogger.ui
    let onSave: (BudgetCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var categoryName = ""
    @State private var allocatedAmount = ""
    @State private var description = ""
    @State private var selectedPriority = BudgetPriority.medium
    @State private var selectedColor = "#3B82F6"
    @State private var isEssential = false
    @State private var selectedTemplate: CategoryTemplate?

    // Common budget category templates
    private let categoryTemplates: [CategoryTemplate] = [
        CategoryTemplate(
            name: "Venue",
            percentage: 40,
            color: "#3B82F6",
            isEssential: true,
            priority: .high,
            description: "Reception and ceremony venue costs"),
        CategoryTemplate(
            name: "Catering",
            percentage: 25,
            color: "#10B981",
            isEssential: true,
            priority: .high,
            description: "Food and beverage service"),
        CategoryTemplate(
            name: "Photography",
            percentage: 8,
            color: "#8B5CF6",
            isEssential: true,
            priority: .medium,
            description: "Wedding photography and videography"),
        CategoryTemplate(
            name: "Flowers & Decorations",
            percentage: 7,
            color: "#F59E0B",
            isEssential: false,
            priority: .medium,
            description: "Floral arrangements and decorative elements"),
        CategoryTemplate(
            name: "Attire",
            percentage: 5,
            color: "#EF4444",
            isEssential: true,
            priority: .medium,
            description: "Wedding dress, suit, and accessories"),
        CategoryTemplate(
            name: "Music & Entertainment",
            percentage: 4,
            color: "#06B6D4",
            isEssential: false,
            priority: .medium,
            description: "DJ, band, or other entertainment"),
        CategoryTemplate(
            name: "Transportation",
            percentage: 3,
            color: "#84CC16",
            isEssential: false,
            priority: .low,
            description: "Transportation for wedding party and guests"),
        CategoryTemplate(
            name: "Stationery",
            percentage: 2,
            color: "#F97316",
            isEssential: false,
            priority: .low,
            description: "Invitations, programs, and printed materials"),
        CategoryTemplate(
            name: "Beauty",
            percentage: 2,
            color: "#EC4899",
            isEssential: false,
            priority: .medium,
            description: "Hair, makeup, and beauty services"),
        CategoryTemplate(
            name: "Cake & Desserts",
            percentage: 2,
            color: "#6366F1",
            isEssential: false,
            priority: .low,
            description: "Wedding cake and dessert service"),
        CategoryTemplate(
            name: "Rings",
            percentage: 1,
            color: "#D946EF",
            isEssential: true,
            priority: .high,
            description: "Wedding bands and engagement ring"),
        CategoryTemplate(
            name: "Miscellaneous",
            percentage: 1,
            color: "#6B7280",
            isEssential: false,
            priority: .low,
            description: "Other wedding-related expenses")
    ]

    private let colorOptions = [
        "#3B82F6", "#10B981", "#8B5CF6", "#F59E0B", "#EF4444",
        "#06B6D4", "#84CC16", "#F97316", "#EC4899", "#6366F1",
        "#D946EF", "#6B7280", "#1F2937", "#065F46", "#7C2D12"
    ]

    private var isFormValid: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !allocatedAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            Double(allocatedAmount) != nil &&
            Double(allocatedAmount) ?? 0 > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Templates") {
                    Text("Choose a template to get started, or create a custom category")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(categoryTemplates, id: \.name) { template in
                            TemplateCardView(
                                template: template,
                                isSelected: selectedTemplate?.name == template.name) {
                                selectTemplate(template)
                            }
                        }
                    }
                }

                Section("Basic Information") {
                    TextField("Category Name", text: $categoryName)

                    TextField("Allocated Amount", text: $allocatedAmount)
                        .overlay(alignment: .leading) {
                            Text("$")
                                .foregroundColor(.secondary)
                                .padding(.leading, Spacing.sm)
                        }
                        .padding(.leading, Spacing.lg)

                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(2 ... 4)
                }

                Section("Category Settings") {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(BudgetPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Essential Category", isOn: $isEssential)
                        .help("Essential categories are required for the wedding")
                }

                Section("Visual Settings") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Color")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                }) {
                                    Circle()
                                        .fill(Color(hex: color) ?? .blue)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedColor == color ? Color.primary : Color.clear,
                                                    lineWidth: 2))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }

                if let amount = Double(allocatedAmount), amount > 0 {
                    Section("Budget Information") {
                        HStack {
                            Text("Allocated Amount")
                            Spacer()
                            Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        if let template = selectedTemplate {
                            HStack {
                                Text("Typical Percentage")
                                Spacer()
                                Text("\(template.percentage)% of total budget")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Budget Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveBudgetCategory()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func selectTemplate(_ template: CategoryTemplate) {
        selectedTemplate = template
        categoryName = template.name
        selectedPriority = template.priority
        selectedColor = template.color
        isEssential = template.isEssential
        description = template.description

        // Don't set amount automatically - let user decide
    }

    private func saveBudgetCategory() {
        guard let amount = Double(allocatedAmount) else { return }

        let newCategory = BudgetCategory(
            id: UUID(),
            coupleId: UUID(), // This should come from current user/couple context
            categoryName: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
            parentCategoryId: nil,
            allocatedAmount: amount,
            spentAmount: 0,
            typicalPercentage: 0.0, // Will be calculated based on total budget
            priorityLevel: selectedPriority.sortOrder,
            isEssential: isEssential,
            notes: nil,
            forecastedAmount: amount,
            confidenceLevel: 0.8, // Default confidence level
            lockedAllocation: false,
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            updatedAt: nil)

        onSave(newCategory)
        dismiss()
    }
}

// MARK: - Supporting Types and Views

struct CategoryTemplate {
    let name: String
    let percentage: Int
    let color: String
    let isEssential: Bool
    let priority: BudgetPriority
    let description: String
}

struct TemplateCardView: View {
    let template: CategoryTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: template.color) ?? .blue)
                    .frame(width: 20, height: 20)

                Text(template.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("\(template.percentage)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.xs)
            .frame(minHeight: 70)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AddBudgetCategoryView { category in
        // TODO: Implement action - print("Saved category: \(category.categoryName)")
    }
}
