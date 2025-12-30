//
//  VendorDetailModalTabBar.swift
//  I Do Blueprint
//
//  Tab bar component for vendor detail modal
//

import SwiftUI

struct VendorDetailModalTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            VendorModalTabButton(title: "Overview", icon: "info.circle", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            VendorModalTabButton(title: "Financial", icon: "dollarsign.circle", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            VendorModalTabButton(title: "Documents", icon: "doc.text", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            VendorModalTabButton(title: "Notes", icon: "note.text", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .background(AppColors.textPrimary)
    }
}

// MARK: - Tab Button

struct VendorModalTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(Typography.bodyRegular)
            }
            .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Rectangle()
                    .fill(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
            )
            .overlay(
                Rectangle()
                    .fill(isSelected ? AppColors.primary : Color.clear)
                    .frame(height: 2),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}
