import MusicKit
import SwiftData
import SwiftUI

struct HiddenAlbumsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HiddenAlbum.hiddenAt, order: .reverse) private var hidden: [HiddenAlbum]

    var body: some View {
        List {
            ForEach(hidden) { hiddenAlbum in
                HStack {
                    Text(hiddenAlbum.albumID)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Unhide") {
                        unhide(hiddenAlbum)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle("Hidden Albums")
        .overlay {
            if hidden.isEmpty {
                ContentUnavailableView(
                    "No Hidden Albums",
                    systemImage: "eye",
                    description: Text("Albums you hide from the main list will show up here.")
                )
            }
        }
    }

    private func unhide(_ hiddenAlbum: HiddenAlbum) {
        withAnimation {
            modelContext.delete(hiddenAlbum)
        }
    }
}

