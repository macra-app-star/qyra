import SwiftUI
import SwiftData
import PhotosUI

struct ProgressPhotosSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProgressPhoto.timestamp, order: .reverse) var photos: [ProgressPhoto]

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedFullScreenPhoto: ProgressPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Progress Photos")
                .font(DesignTokens.Typography.headlineFont(24))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if photos.isEmpty {
                emptyState
            } else {
                photosGrid
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                guard let item else { return }
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                    let photo = ProgressPhoto(imageData: compressed)
                    modelContext.insert(photo)
                    try? modelContext.save()
                }
                selectedPhoto = nil
            }
        }
        .sheet(item: $selectedFullScreenPhoto) { photo in
            fullScreenView(for: photo)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("No Photos Yet")
                .font(.headline)
                .foregroundStyle(Color(.label))

            Text("Upload a photo to track your progress.")
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Upload Photo")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Photos Grid

    private var photosGrid: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(photos) { photo in
                        if let uiImage = UIImage(data: photo.imageData) {
                            Button {
                                selectedFullScreenPhoto = photo
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.horizontal, -DesignTokens.Spacing.md)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Upload Photo")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Full Screen View

    private func fullScreenView(for photo: ProgressPhoto) -> some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                }

                VStack {
                    Spacer()
                    Text(photo.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedFullScreenPhoto = nil
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    ProgressPhotosSection()
        .padding()
        .background(DesignTokens.Colors.background)
        .modelContainer(for: ProgressPhoto.self, inMemory: true)
}
