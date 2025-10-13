import SwiftUI

struct ContentViewV2: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var selectedTab = 0

    // Navigation items
    private let navigationItems = [
        NavigationItem(icon: "house.fill", label: "Dashboard"),
        NavigationItem(icon: "person.3.fill", label: "Guests"),
        NavigationItem(icon: "building.2.fill", label: "Vendors"),
        NavigationItem(icon: "dollarsign.circle.fill", label: "Budget"),
        NavigationItem(icon: "paintpalette.fill", label: "Visual Planning"),
        NavigationItem(icon: "note.text", label: "Notes"),
        NavigationItem(icon: "doc.fill", label: "Documents"),
        NavigationItem(icon: "gearshape.fill", label: "Settings"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            Group {
                switch selectedTab {
                case 0: DashboardViewV2()
                case 1: GuestListViewV2()
                case 2: VendorListViewV2()
                case 3: BudgetMainView()
                case 4: VisualPlanningMainView()
                case 5: NotesView()
                case 6: DocumentsView()
                case 7: SettingsView()
                default: DashboardViewV2()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom navigation bar
            VStack {
                Spacer()
                NavigationBarV2(selectedTab: $selectedTab, items: navigationItems)
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    ContentViewV2()
}
