import MusicKit
import Combine
import SwiftUI

@MainActor
final class PlayerObserver: ObservableObject {
    @Published private(set) var playbackStatus: MusicPlayer.PlaybackStatus = .stopped
    @Published private(set) var nowPlayingTitle: String = ""
    @Published private(set) var nowPlayingSubtitle: String = ""
    @Published private(set) var artwork: Artwork?

    private let player = SystemMusicPlayer.shared

    func refresh() {
        playbackStatus = player.state.playbackStatus

        if let item = player.queue.currentEntry?.item {
            // CurrentEntry.item is a MusicPlayable; we use KVC-free string fallbacks.
            nowPlayingTitle = (item as? Song)?.title ?? (item as? Track)?.title ?? "Now Playing"
            nowPlayingSubtitle = (item as? Song)?.artistName ?? (item as? Track)?.artistName ?? ""
            artwork = (item as? Song)?.artwork ?? (item as? Track)?.artwork
        } else {
            nowPlayingTitle = ""
            nowPlayingSubtitle = ""
            artwork = nil
        }
    }

    func togglePlayPause() async {
        if player.state.playbackStatus == .playing {
            await player.pause()
        } else {
            try? await player.play()
        }
        refresh()
    }

    func next() async {
        do { try await player.skipToNextEntry() } catch {}
        refresh()
    }

    func previous() async {
        do { try await player.skipToPreviousEntry() } catch {}
        refresh()
    }
}

struct MiniPlayerBar: View {
    @StateObject private var observer = PlayerObserver()

    var body: some View {
        if observer.nowPlayingTitle.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 12) {
                ArtworkImage(observer.artwork, width: 44, height: 44)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(observer.nowPlayingTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if !observer.nowPlayingSubtitle.isEmpty {
                        Text(observer.nowPlayingSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    Task { await observer.previous() }
                } label: {
                    Image(systemName: "backward.fill")
                }
                .buttonStyle(.plain)

                Button {
                    Task { await observer.togglePlayPause() }
                } label: {
                    Image(systemName: observer.playbackStatus == .playing ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.plain)

                Button {
                    Task { await observer.next() }
                } label: {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .task {
                observer.refresh()
            }
            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                observer.refresh()
            }
        }
    }
}

