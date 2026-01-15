//
//  ContentView.swift
//  Only Albums
//
//  Created by Scott Koellner on 1/15/26.
//

import SwiftUI
import SwiftData
import MusicKit

struct ContentView: View {
    @StateObject private var musicClient = MusicClient()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack {
                    AlbumListView(musicClient: musicClient)
                }
                .tabItem {
                    Label("Albums", systemImage: "rectangle.stack")
                }

                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .task {
                _ = await musicClient.ensureAuthorized()
            }

            MiniPlayerBar()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: HiddenAlbum.self, inMemory: true)
}
