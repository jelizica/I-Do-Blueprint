import SwiftUI

/// Export options sheet for expense reports
struct ExpenseExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let expenses: [Expense]
    let categories: [BudgetCategory]
    
    @State private var isExporting = false
    @State private var exportError: Error?
    private let exportService = BudgetExportService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export Options")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    ExportOptionButton(
                        title: "Export as PDF",
                        description: "Generate a formatted PDF report",
                        icon: "doc.fill",
                        color: AppColors.Budget.expense) {
                        Task {
                            isExporting = true
                            do {
                                let fileURL = try await exportService.exportExpenses(
                                    expenses: expenses,
                                    categories: categories,
                                    format: .pdf
                                )
                                dismiss()
                                await MainActor.run {
                                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                                }
                            } catch {
                                exportError = error
                                AppLogger.ui.error("PDF export failed", error: error)
                            }
                            isExporting = false
                        }
                    }
                    
                    ExportOptionButton(
                        title: "Export as CSV",
                        description: "Export raw data for spreadsheet analysis",
                        icon: "tablecells.fill",
                        color: AppColors.Budget.income) {
                        Task {
                            isExporting = true
                            do {
                                let fileURL = try await exportService.exportExpenses(
                                    expenses: expenses,
                                    categories: categories,
                                    format: .csv
                                )
                                dismiss()
                                await MainActor.run {
                                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                                }
                            } catch {
                                exportError = error
                                AppLogger.ui.error("CSV export failed", error: error)
                            }
                            isExporting = false
                        }
                    }
                    
                    ExportOptionButton(
                        title: "Share Report",
                        description: "Share via email or messaging",
                        icon: "square.and.arrow.up.fill",
                        color: AppColors.Budget.allocated) {
                        Task {
                            isExporting = true
                            do {
                                let fileURL = try await exportService.exportExpenses(
                                    expenses: expenses,
                                    categories: categories,
                                    format: .pdf
                                )
                                dismiss()
                                await MainActor.run {
                                    exportService.showShareSheet(for: fileURL)
                                }
                            } catch {
                                exportError = error
                                AppLogger.ui.error("Share failed", error: error)
                            }
                            isExporting = false
                        }
                    }
                }
                .disabled(isExporting)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Report")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct ExportOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.quaternarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
