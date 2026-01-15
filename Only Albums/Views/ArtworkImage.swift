import MusicKit
import SwiftUI

struct ArtworkImage: View {
    let artwork: Artwork?
    let width: CGFloat?
    let height: CGFloat?

    init(_ artwork: Artwork?, width: CGFloat?, height: CGFloat?) {
        self.artwork = artwork
        self.width = width
        self.height = height
    }

    var body: some View {
        Group {
            if let artwork, let url = artwork.url(width: Int(width ?? 600), height: Int(height ?? 600)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .background(.quaternary)
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: "music.note")
                .foregroundStyle(.secondary)
        }
    }
}

