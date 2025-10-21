//
//  GuestOverviewTab.swift
//  I Do Blueprint
//
//  Overview tab content for guest detail view
//

import SwiftUI

struct GuestOverviewTab: View {
    let guest: Guest
    let onEdit: () -> Void
    @EnvironmentObject var settingsStore: SettingsStoreV2
    
    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            // Quick Actions Toolbar
            QuickActionsToolbar(actions: quickActions)
            
            // Quick Info Cards
            QuickInfoSection(guest: guest)
        }
    }
    
    private var quickActions: [QuickAction] {
        var actions: [QuickAction] = []
        
        // Call action
        if let phone = guest.phone {
            actions.append(QuickAction(icon: "phone.fill", title: "Call", color: .green) {
                if let url = URL(string: "tel:\(phone.filter { !$0.isWhitespace && $0 != "-" && $0 != "(" && $0 != ")" })") {
                    NSWorkspace.shared.open(url)
                }
            })
        }
        
        // Email action
        if let email = guest.email {
            actions.append(QuickAction(icon: "envelope.fill", title: "Email", color: .blue) {
                if let url = URL(string: "mailto:\(email)") {
                    NSWorkspace.shared.open(url)
                }
            })
        }
        
        // Edit action
        actions.append(QuickAction(icon: "pencil", title: "Edit", color: AppColors.primary) {
            onEdit()
        })
        
        return actions
    }
}
