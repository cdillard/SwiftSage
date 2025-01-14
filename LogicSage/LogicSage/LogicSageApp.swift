//
//  LogicSageApp.swift
//  LogicSage
//
//  Created by Chris Dillard on 4/23/23.
//████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
// █░░░░░░█████████░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█
// █░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
// █░░▄▀░░█████████░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█░░░░▄▀░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█
// █░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░███████████░░▄▀░░███░░▄▀░░█████████░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░█████████
// █░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░███████████░░▄▀░░███░░▄▀░░█████████░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░█████████░░▄▀░░░░░░░░░░█
// █░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░░░░░███░░▄▀░░███░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░░░░░█░░▄▀▄▀▄▀▄▀▄▀░░█
// █░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░███░░▄▀░░███░░▄▀░░█████████░░░░░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░░░░░█
// █░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░███░░▄▀░░███░░▄▀░░█████████████████░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░█████████
// █░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░░░▄▀░░░░█░░▄▀░░░░░░░░░░█░░░░░░░░░░▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█
// █░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░██░░▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█
//
//
//

import SwiftUI
import Combine

#if !os(macOS)
import UIKit
#endif

var serviceDiscovery: ServiceDiscovery?

@main
struct LogicSageApp: App {

    @StateObject var appModel = AppModel()

    @StateObject private var settingsViewModel = SettingsViewModel.shared

#if os(visionOS)
    @State var immersionState: ImmersionStyle = .mixed
#endif

    init() {
        serviceDiscovery = ServiceDiscovery()

    }
    var body: some Scene {
        WindowGroup("LogicSage", id: "LogicSage-main") {
            ContentView(settingsViewModel: settingsViewModel)
                .environmentObject(appModel)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.666) {

                        serviceDiscovery?.startDiscovering()
                    }
                    DispatchQueue.global(qos: .default).async {
                        settingsViewModel.printVoicesInMyDevice()
                        settingsViewModel.configureAudioSession()
                    }

                }
#if !os(macOS)
#if !os(visionOS)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                    //logD("didFinishLaunchingNotification")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                   // logD("applicationWillEnterForeground")

                    screamer.discoReconnect()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                   // logD("didEnterBackgroundNotification")
                }
#endif
#endif
#if !os(visionOS)
                .preferredColorScheme(.dark)
#endif
        }

#if os(visionOS)
        .windowStyle(.plain)
#endif
#if os(visionOS)

        ImmersiveSpace(id: "ImmersiveSpace") {
            SphereScreenSceneView()
                .environmentObject(appModel)
        }
        .immersionStyle(selection: $immersionState, in: .mixed)

        WindowGroup(id: "LogoVolume") {
            ImmersiveLogoView()
                .environmentObject(appModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
#endif
    }
}
