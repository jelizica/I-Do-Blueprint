//
//  LinksSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct LinksSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    @State private var showAddLink = false
    @State private var editingLink: ImportantLink?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Important Links",
                subtitle: "Manage bookmarks and important wedding-related URLs",
                sectionName: "links",
                isSaving: viewModel.savingSections.contains("links"),
                hasUnsavedChanges: viewModel.localSettings.links != viewModel.settings.links,
                onSave: {
                    Task {
                        await viewModel.saveLinksSettings()
                    }
                })

            Divider()

            GroupBox(label: HStack {
                Image(systemName: "link.circle")
                Text("Your Links")
                    .font(.headline)
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Store important URLs like vendor websites, inspiration boards, registries, and more.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if viewModel.localSettings.links.importantLinks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No links saved yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text("Add important links to keep everything organized in one place")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Spacing.huge)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.localSettings.links.importantLinks) { link in
                                    LinkRow(
                                        link: link,
                                        onEdit: { editingLink = link },
                                        onDelete: { removeLink(link) })
                                }
                            }
                        }
                        .frame(maxHeight: 400)
                    }

                    Button(action: { showAddLink = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Link")
                        }
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showAddLink) {
            AddLinkSheet(
                onSave: { title, url, description in
                    addLink(title: title, url: url, description: description)
                    showAddLink = false
                },
                onCancel: { showAddLink = false })
        }
        .sheet(item: $editingLink) { link in
            EditLinkSheet(
                link: link,
                onSave: { title, url, description in
                    updateLink(link, title: title, url: url, description: description)
                    editingLink = nil
                },
                onCancel: { editingLink = nil })
        }
    }

    private func addLink(title: String, url: String, description: String?) {
        let newLink = ImportantLink(
            id: UUID().uuidString,
            title: title,
            url: url,
            description: description)
        viewModel.localSettings.links.importantLinks.append(newLink)
    }

    private func updateLink(_ link: ImportantLink, title: String, url: String, description: String?) {
        if let index = viewModel.localSettings.links.importantLinks.firstIndex(where: { $0.id == link.id }) {
            viewModel.localSettings.links.importantLinks[index] = ImportantLink(
                id: link.id,
                title: title,
                url: url,
                description: description)
        }
    }

    private func removeLink(_ link: ImportantLink) {
        viewModel.localSettings.links.importantLinks.removeAll { $0.id == link.id }
    }
}

// MARK: - Link Row

struct LinkRow: View {
    let link: ImportantLink
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(link.title)
                        .font(.body)
                        .fontWeight(.medium)

                    if let url = InputValidator.safeURLConversion(link.url) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption)
                                Text(link.url)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundColor(.blue)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                            Text("Invalid URL: \(link.url)")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.red)
                    }

                    if let description = link.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
            }

            Divider()
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Add Link Sheet

struct AddLinkSheet: View {
    let onSave: (String, String, String?) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var url = ""
    @State private var description = ""
    @State private var validationError: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Important Link")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Wedding Registry, Venue Website", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: title) { _, _ in
                            validationError = nil
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("URL")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("https://example.com", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: url) { _, _ in
                            validationError = nil
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Brief description of this link", text: $description)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let error = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Add") {
                    handleSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || url.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
    }

    private func handleSave() {
        // Validate URL
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationError = "Title cannot be empty"
            return
        }

        guard !trimmedUrl.isEmpty else {
            validationError = "URL cannot be empty"
            return
        }

        // Basic URL validation
        guard trimmedUrl.starts(with: "http://") || trimmedUrl.starts(with: "https://") else {
            validationError = "URL must start with http:// or https://"
            return
        }

        guard URL(string: trimmedUrl) != nil else {
            validationError = "Please enter a valid URL"
            return
        }

        let finalDescription = description.isEmpty ? nil : description
        onSave(trimmedTitle, trimmedUrl, finalDescription)
    }
}

// MARK: - Edit Link Sheet

struct EditLinkSheet: View {
    let link: ImportantLink
    let onSave: (String, String, String?) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var url: String
    @State private var description: String
    @State private var validationError: String?

    init(link: ImportantLink, onSave: @escaping (String, String, String?) -> Void, onCancel: @escaping () -> Void) {
        self.link = link
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: link.title)
        _url = State(initialValue: link.url)
        _description = State(initialValue: link.description ?? "")
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Link")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: title) { _, _ in
                            validationError = nil
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("URL")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("URL", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: url) { _, _ in
                            validationError = nil
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Description", text: $description)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if let error = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Save") {
                    handleSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || url.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
    }

    private func handleSave() {
        // Validate URL
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationError = "Title cannot be empty"
            return
        }

        guard !trimmedUrl.isEmpty else {
            validationError = "URL cannot be empty"
            return
        }

        // Basic URL validation
        guard trimmedUrl.starts(with: "http://") || trimmedUrl.starts(with: "https://") else {
            validationError = "URL must start with http:// or https://"
            return
        }

        guard URL(string: trimmedUrl) != nil else {
            validationError = "Please enter a valid URL"
            return
        }

        let finalDescription = description.isEmpty ? nil : description
        onSave(trimmedTitle, trimmedUrl, finalDescription)
    }
}

#Preview {
    LinksSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700, height: 700)
}
