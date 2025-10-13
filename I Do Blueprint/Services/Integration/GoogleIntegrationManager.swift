import Combine
import Foundation

@MainActor
class GoogleIntegrationManager: ObservableObject {
    let authManager: GoogleAuthManager
    let driveManager: GoogleDriveManager
    let sheetsManager: GoogleSheetsManager

    private var cancellables = Set<AnyCancellable>()

    init() {
        let auth = GoogleAuthManager()
        authManager = auth
        driveManager = GoogleDriveManager(authManager: auth)
        sheetsManager = GoogleSheetsManager(authManager: auth)

        // Forward authManager changes to this manager
        auth.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
}
