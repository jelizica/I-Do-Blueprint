import SwiftUI

/// Menu for exporting budget in various formats
struct BudgetExportMenu: View {
    @Binding var uploading: Bool
    
    let isGoogleAuthenticated: Bool
    
    let onExportJSON: () -> Void
    let onExportCSV: () -> Void
    let onExportToGoogleDrive: () async -> Void
    let onExportToGoogleSheets: () async -> Void
    let onSignInToGoogle: () async -> Void
    let onSignOutFromGoogle: () -> Void
    
    var body: some View {
        Menu {
            Section("Local Export") {
                Button(action: onExportJSON) {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                
                Button(action: onExportCSV) {
                    Label("Export as CSV", systemImage: "tablecells")
                }
            }
            
            Divider()
            
            Section("Google Export") {
                if isGoogleAuthenticated {
                    Button(action: {
                        Task {
                            await onExportToGoogleDrive()
                        }
                    }) {
                        Label("Export to Google Drive", systemImage: "cloud.fill")
                    }
                    .disabled(uploading)
                    
                    Button(action: {
                        Task {
                            await onExportToGoogleSheets()
                        }
                    }) {
                        Label("Export to Google Sheets", systemImage: "tablecells.fill")
                    }
                    .disabled(uploading)
                    
                    Divider()
                    
                    Button(action: onSignOutFromGoogle) {
                        Label("Sign Out from Google", systemImage: "person.crop.circle.badge.xmark")
                    }
                } else {
                    Button(action: {
                        Task {
                            await onSignInToGoogle()
                        }
                    }) {
                        Label("Sign In to Google", systemImage: "person.crop.circle.badge.checkmark")
                    }
                }
            }
        } label: {
            HStack {
                if uploading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text("Export")
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
