//
//  PresenceIndicator.swift
//  I Do Blueprint
//
//  Presence indicator component for showing online collaborators
//

import SwiftUI

/// Shows online presence for collaborators
struct PresenceIndicator: View {
    @StateObject private var presenceStore = PresenceStoreV2()
    let size: IndicatorSize
    
    enum IndicatorSize {
        case small, medium, large
        
        var avatarSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 40
            }
        }
        
        var statusSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
    }
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(presenceStore.onlineUsers.prefix(3)), id: \.id) { presence in
                PresenceAvatar(
                    displayName: presence.userId.uuidString,
                    isOnline: presence.isOnline,
                    size: size
                )
            }
            
            if presenceStore.onlineCount > 3 {
                MoreUsersIndicator(
                    count: presenceStore.onlineCount - 3,
                    size: size
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(presenceStore.onlineCount) users online")
        .task {
            await presenceStore.loadActivePresence()
        }
    }
}

/// Individual presence avatar
struct PresenceAvatar: View {
    let displayName: String
    let isOnline: Bool
    let size: PresenceIndicator.IndicatorSize
    
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: size.avatarSize, height: size.avatarSize)
                .overlay(
                    Text(initials)
                        .font(.system(size: size.avatarSize * 0.4, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                )
                .overlay(
                    Circle()
                        .stroke(AppColors.background, lineWidth: 2)
                )
            
            if isOnline {
                Circle()
                    .fill(AppColors.success)
                    .frame(width: size.statusSize, height: size.statusSize)
                    .overlay(
                        Circle()
                            .stroke(AppColors.background, lineWidth: 1.5)
                    )
            }
        }
        .accessibilityLabel("\(displayName), \(isOnline ? "online" : "offline")")
    }
}

/// More users indicator
struct MoreUsersIndicator: View {
    let count: Int
    let size: PresenceIndicator.IndicatorSize
    
    var body: some View {
        Circle()
            .fill(AppColors.cardBackground)
            .frame(width: size.avatarSize, height: size.avatarSize)
            .overlay(
                Text("+\(count)")
                    .font(.system(size: size.avatarSize * 0.35, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            )
            .overlay(
                Circle()
                    .stroke(AppColors.background, lineWidth: 2)
            )
            .accessibilityLabel("\(count) more users online")
    }
}

/// Compact presence count badge
struct PresenceCountBadge: View {
    @StateObject private var presenceStore = PresenceStoreV2()
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppColors.success)
                .frame(width: 8, height: 8)
            
            Text("\(presenceStore.onlineCount)")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .accessibilityLabel("\(presenceStore.onlineCount) users online")
        .task {
            await presenceStore.loadActivePresence()
        }
    }
}

// MARK: - Previews

#Preview("Presence Indicator - Small") {
    PresenceIndicator(size: .small)
        .padding()
}

#Preview("Presence Indicator - Medium") {
    PresenceIndicator(size: .medium)
        .padding()
}

#Preview("Presence Indicator - Large") {
    PresenceIndicator(size: .large)
        .padding()
}

#Preview("Presence Count Badge") {
    PresenceCountBadge()
        .padding()
}
