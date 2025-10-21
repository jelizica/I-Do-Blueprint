import SwiftUI

/// Filters section for expense reports
struct ExpenseReportsFilters: View {
    @Binding var searchText: String
    @Binding var filters: FilterState
    
    let categoryOptions: [String]
    let vendorOptions: [String]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.blue)
                Text("Filters")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search expenses...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Filter pickers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Category", selection: $filters.category) {
                            ForEach(categoryOptions, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vendor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Vendor", selection: $filters.vendor) {
                            ForEach(vendorOptions, id: \.self) { vendor in
                                Text(vendor).tag(vendor)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Payment Status", selection: $filters.paymentStatus) {
                            ForEach(PaymentStatusOption.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date Range")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Date Range", selection: $filters.dateRange) {
                            ForEach(DateRange.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
        .padding()
        .background(Color(.quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
