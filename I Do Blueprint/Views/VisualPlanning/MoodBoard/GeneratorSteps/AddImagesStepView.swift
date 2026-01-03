//
//  AddImagesStepView.swift
//  My Wedding Planning App
//
//  Image addition step for mood board generator
//

import SwiftUI
import UniformTypeIdentifiers

struct AddImagesStepView: View {
    @Binding var state: MoodBoardGeneratorState
    @ObservedObject var colorExtractionService: ColorExtractionService

    @State private var dragOver = false
    @State private var isImporting = false
    @State private var importProgress: Double = 0
    @State private var selectedTab: ImageSourceTab = .upload

    private let logger = AppLogger.ui

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("Add Images")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Upload images or import from the web to create your mood board")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Tab Selection
                Picker("Image Source", selection: $selectedTab) {
                    ForEach(ImageSourceTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab Content
                switch selectedTab {
                case .upload:
                    uploadTabContent
                case .web:
                    webImportTabContent
                case .library:
                    libraryTabContent
                }

                // Selected Images
                if !state.selectedImages.isEmpty {
                    selectedImagesSection
                }
            }
        }
    }

    // MARK: - Upload Tab

    private var uploadTabContent: some View {
        VStack(spacing: 20) {
            // Drop Zone
            DropZone(
                dragOver: $dragOver,
                isImporting: $isImporting,
                onFilesDropped: handleFilesDrop)

            // Or divider
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            .padding(.horizontal)

            // File picker button
            Button(action: showFilePicker) {
                HStack {
                    Image(systemName: "folder")
                    Text("Browse Files")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.blue)
                .foregroundColor(SemanticColors.textPrimary)
                .cornerRadius(8)
            }

            if isImporting {
                ProgressView("Importing images...", value: importProgress)
                    .padding()
            }
        }
        .padding()
    }

    // MARK: - Web Import Tab

    private var webImportTabContent: some View {
        VStack(spacing: 20) {
            WebImageImportView { imageData in
                Task {
                    await addImageFromData(imageData, source: "web")
                }
            }
        }
        .padding()
    }

    // MARK: - Library Tab

    private var libraryTabContent: some View {
        VStack(spacing: 20) {
            Text("Stock Photo Library")
                .font(.headline)

            Text("Coming soon: Browse curated wedding photos")
                .font(.body)
                .foregroundColor(.secondary)

            StockPhotoLibraryView { imageData in
                Task {
                    await addImageFromData(imageData, source: "library")
                }
            }
        }
        .padding()
    }

    // MARK: - Selected Images Section

    private var selectedImagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            HStack {
                Text("Selected Images (\(state.selectedImages.count))")
                    .font(.headline)

                Spacer()

                Button("Clear All") {
                    state.selectedImages.removeAll()
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(state.selectedImages) { element in
                        SelectedImageCard(element: element) {
                            removeImage(element)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - File Handling

    private func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            Task {
                await handleSelectedFiles(panel.urls)
            }
        }
    }

    private func handleFilesDrop(_ providers: [NSItemProvider]) {
        Task {
            isImporting = true
            importProgress = 0

            for (index, provider) in providers.enumerated() {
                importProgress = Double(index) / Double(providers.count)

                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    do {
                        let data = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil)
                        if let imageData = data as? Data {
                            await addImageFromData(imageData, source: "upload")
                        } else if let url = data as? URL {
                            let imageData = try Data(contentsOf: url)
                            await addImageFromData(imageData, source: "upload", filename: url.lastPathComponent)
                        }
                    } catch {
                        logger.error("Failed to load image", error: error)
                    }
                }
            }

            importProgress = 1.0
            isImporting = false
        }
    }

    private func handleSelectedFiles(_ urls: [URL]) async {
        isImporting = true
        importProgress = 0

        for (index, url) in urls.enumerated() {
            importProgress = Double(index) / Double(urls.count)

            do {
                let imageData = try Data(contentsOf: url)
                await addImageFromData(imageData, source: "upload", filename: url.lastPathComponent)
            } catch {
                logger.error("Failed to load image from \(url)", error: error)
            }
        }

        importProgress = 1.0
        isImporting = false
    }

    @MainActor
    private func addImageFromData(_ data: Data, source _: String, filename: String? = nil) async {
        guard let nsImage = NSImage(data: data) else { return }

        // Convert to base64 for storage
        let base64String = data.base64EncodedString()
        let dataURL = "data:image/png;base64,\(base64String)"

        let element = VisualElement(
            moodBoardId: UUID(), // Will be set when mood board is created
            elementType: .image,
            elementData: VisualElement.ElementData(
                imageUrl: dataURL,
                originalFilename: filename ?? "Image",
                fileSize: Int64(data.count),
                dimensions: nsImage.size,
                alt: "Uploaded image: \(filename ?? "Image")"),
            position: CGPoint(
                x: CGFloat.random(in: 50 ... 200),
                y: CGFloat.random(in: 50 ... 200)),
            size: CGSize(
                width: min(200, nsImage.size.width),
                height: min(200, nsImage.size.height)),
            zIndex: state.selectedImages.count + 1)

        state.selectedImages.append(element)

        // Auto-extract colors from first image if no palette exists
        if state.selectedImages.count == 1, state.colorPalette == nil {
            await extractColorsFromFirstImage(nsImage)
        }
    }

    private func extractColorsFromFirstImage(_ image: NSImage) async {
        do {
            let result = try await colorExtractionService.extractColors(
                from: image,
                algorithm: .vibrant,
                options: ColorExtractionOptions(maxColors: 4))

            await MainActor.run {
                if result.colors.count >= 4 {
                    state.colorPalette = ExtractedColorPalette(
                        name: "Auto-extracted from \(state.selectedImages.first?.elementData.originalFilename ?? "image")",
                        primaryColor: result.colors[0],
                        secondaryColor: result.colors[1],
                        accentColor: result.colors[2],
                        neutralColor: result.colors[3],
                        extractionResult: result)
                }
            }
        } catch {
            logger.error("Color extraction failed", error: error)
        }
    }

    private func removeImage(_ element: VisualElement) {
        state.selectedImages.removeAll { $0.id == element.id }
    }
}

// MARK: - Supporting Views

enum ImageSourceTab: CaseIterable {
    case upload, web, library

    var title: String {
        switch self {
        case .upload: "Upload"
        case .web: "Web Import"
        case .library: "Stock Photos"
        }
    }
}

struct DropZone: View {
    @Binding var dragOver: Bool
    @Binding var isImporting: Bool
    let onFilesDropped: ([NSItemProvider]) -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(dragOver ? Color.blue.opacity(0.2) : SemanticColors.textSecondary.opacity(Opacity.subtle))
            .stroke(
                dragOver ? Color.blue : SemanticColors.textSecondary.opacity(Opacity.light),
                style: StrokeStyle(lineWidth: 2, dash: [8]))
            .frame(height: 200)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: dragOver ? "photo.badge.plus" : "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(dragOver ? .blue : .secondary)

                    VStack(spacing: 4) {
                        Text(dragOver ? "Drop images here" : "Drag & drop images here")
                            .font(.headline)
                            .foregroundColor(dragOver ? .blue : .secondary)

                        Text("Supports PNG, JPEG, and other image formats")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                })
            .onDrop(of: [.image], isTargeted: $dragOver) { providers in
                onFilesDropped(providers)
                return true
            }
            .animation(.easeInOut(duration: 0.2), value: dragOver)
    }
}

struct SelectedImageCard: View {
    let element: VisualElement
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Image preview
            if let imageUrl = element.elementData.imageUrl,
               let data = Data(base64Encoded: String(imageUrl.dropFirst(22))),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(SemanticColors.textSecondary.opacity(Opacity.light))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(SemanticColors.textSecondary))
            }

            // File info
            VStack(spacing: 2) {
                Text(element.elementData.originalFilename ?? "Image")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let fileSize = element.elementData.fileSize {
                    Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .frame(width: 100)
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct WebImageImportView: View {
    let onImageImported: (Data) -> Void
    @State private var urlString = ""
    @State private var isImporting = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Import from Web")
                .font(.headline)

            HStack {
                TextField("Enter image URL...", text: $urlString)
                    .textFieldStyle(.roundedBorder)

                Button("Import") {
                    importFromURL()
                }
                .disabled(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
            }

            if isImporting {
                ProgressView("Importing...")
                    .scaleEffect(0.8)
            }

            Text("Paste a direct link to an image from Pinterest, Instagram, or any website")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func importFromURL() {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }

        isImporting = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    onImageImported(data)
                    urlString = ""
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    // Handle error
                }
            }
        }
    }
}

struct StockPhotoLibraryView: View {
    let onImageSelected: (Data) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Browse curated wedding photos from our stock library")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Placeholder grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(0 ..< 6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColors.textSecondary.opacity(Opacity.light))
                        .frame(height: 100)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(SemanticColors.textSecondary))
                }
            }
        }
    }
}

#Preview {
    @State var sampleState = MoodBoardGeneratorState()
    @StateObject var colorService = ColorExtractionService()

    return AddImagesStepView(
        state: $sampleState,
        colorExtractionService: colorService)
        .frame(width: 800, height: 600)
}
