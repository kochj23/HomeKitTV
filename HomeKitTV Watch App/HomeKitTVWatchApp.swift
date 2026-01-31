//
//  HomeKitTVWatchApp.swift
//  HomeKitTV Watch App
//
//  watchOS companion app for HomeKitTV
//  Quick access to favorite scenes and accessories
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

@main
struct HomeKitTVWatchApp: App {
    @StateObject private var dataStore = WatchDataStore.shared
    @StateObject private var connectivity = WatchPhoneConnectivity.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(dataStore)
                .environmentObject(connectivity)
        }
    }
}
