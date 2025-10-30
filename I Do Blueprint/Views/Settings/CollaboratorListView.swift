//
//  CollaboratorListView.swift
//  I Do Blueprint
//
//  Collaborator management view
//

import SwiftUI

struct CollaboratorListView: View {
    @StateObject private var store = CollaborationStoreV2()
    @State private var showingInviteSheet = false
    @State private var selectedCollaborator: Collaborator?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CollaboratorHeaderView(
                activeCount: store.activeCollaborators.count,
                pendingCount: store.pendingInvitations.count,
                onInvite: { showingInviteSheet = true }
            )
            .disabled(!store.canInvite)
            
            Divider()
            
            // Content
            Group {
                switch store.loadingState {
                case .idle, .loading:
                    ProgressView("Loading collaborators...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .loaded:
                    if store.collaborators.isEmpty {
                        EmptyCollaboratorsView(
                            canInvite: store.canInvite,
                            onInvite: { showingInviteSheet = true }
                        )
                    } else {
                        CollaboratorListContent(
                            store: store,
                            selectedCollaborator: $selectedCollaborator
                        )
                    }
                    
                case .error(let error):
                    ErrorStateView(
                        error: error,
                        onRetry: { Task { await store.retryLoad() } }
                    )
                }
            }
        }
        .navigationTitle("Collaborators")
        .sheet(isPresented: $showingInviteSheet) {
            InviteCollaboratorSheet(store: store)
        }
        .sheet(item: $selectedCollaborator) { collaborator in
            CollaboratorDetailSheet(
                collaborator: collaborator,
                store: store
            )
        }
        .task {
            await store.loadCollaborationData()
        }
        .toast(isPresented: $store.showSuccessToast, message: store.successMessage)
    }
}

// MARK: - Header

struct CollaboratorHeaderView: View {
    let activeCount: Int
    let pendingCount: Int
    let onInvite: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(activeCount) Active")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                if pendingCount > 0 {
                    Text("\(pendingCount) Pending")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: onInvite) {
                Label("Invite", systemImage: "person.badge.plus")
                    .font(.body)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Invite collaborator")
        }
        .padding()
    }
}

// MARK: - List Content

struct CollaboratorListContent: View {
    @ObservedObject var store: CollaborationStoreV2
    @Binding var selectedCollaborator: Collaborator?
    
    var body: some View {
        List {
            if !store.activeCollaborators.isEmpty {
                Section("Active Collaborators") {
                    ForEach(store.activeCollaborators) { collaborator in
                        CollaboratorRow(
                            collaborator: collaborator,
                            role: store.getRoleForId(collaborator.roleId),
                            canManage: store.canManageRoles
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCollaborator = collaborator
                        }
                    }
                }
            }
            
            if !store.pendingInvitations.isEmpty {
                Section("Pending Invitations") {
                    ForEach(store.pendingInvitations) { collaborator in
                        CollaboratorRow(
                            collaborator: collaborator,
                            role: store.getRoleForId(collaborator.roleId),
                            canManage: store.canManageRoles,
                            isPending: true
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCollaborator = collaborator
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Collaborator Row

struct CollaboratorRow: View {
    let collaborator: Collaborator
    let role: CollaborationRole?
    let canManage: Bool
    var isPending: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(AppColors.cardBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(collaborator.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(collaborator.name)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    if let role = role {
                        Text(role.roleName.displayName)
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if isPending {
                        Text("• Pending")
                            .font(.caption)
                            .foregroundColor(AppColors.warning)
                    }
                }
            }
            
            Spacer()
            
            if canManage {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(collaborator.name), \(role?.roleName.displayName ?? ""), \(isPending ? "pending invitation" : "active")")
    }
}

// MARK: - Empty State

struct EmptyCollaboratorsView: View {
    let canInvite: Bool
    let onInvite: () -> Void
    
    var body: some View {
        SharedEmptyStateView(
            icon: "person.2",
            title: "No Collaborators Yet",
            message: "Invite your partner or wedding planner to collaborate on your wedding planning.",
            actionTitle: canInvite ? "Invite Collaborator" : nil,
            action: canInvite ? onInvite : nil
        )
    }
}

// MARK: - Toast Modifier

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.success)
                            Text(message)
                                .font(.body)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    isPresented.wrappedValue = false
                                }
                            }
                        }
                    }
                }
            }
        )
    }
}

// MARK: - Previews

#Preview("Collaborator List") {
    NavigationStack {
        CollaboratorListView()
    }
}
