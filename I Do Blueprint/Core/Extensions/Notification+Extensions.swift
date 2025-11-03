//
//  Notification+Extensions.swift
//  I Do Blueprint
//
//  Notification names used throughout the app
//

import Foundation

extension Notification.Name {
    /// Posted when settings are updated
    static let settingsDidChange = Notification.Name("settingsDidChange")

    /// Posted when the tenant (couple/wedding) changes
    /// UserInfo contains: "previousId" (String), "newId" (String)
    static let tenantDidChange = Notification.Name("tenantDidChange")
}
