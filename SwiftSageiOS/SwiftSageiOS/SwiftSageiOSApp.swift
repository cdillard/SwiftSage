//
//  SwiftSageiOSApp.swift
//  SwiftSageiOS
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

// TODO MAKE SURE ITS OKAY TO UP THIS SO MUCH
let STRING_LIMIT = 150000

// TODO BEFORE RELEASE: PROD BUNDLE ID
// TODO USE BUILT IN BundleID var.
let bundleID = "com.chrisdillard.SwiftSage"

var serviceDiscovery: ServiceDiscovery?

@main
struct SwiftSageiOSApp: App {
    @StateObject private var settingsViewModel = SettingsViewModel.shared
    @StateObject private var appState = AppState()
    @State private var isDrawerOpen = false
#if !os(macOS)

    @State private var isPortrait = UIApplication.shared.statusBarOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown
#endif

    init() {
        serviceDiscovery = ServiceDiscovery()
    }
    var body: some Scene {
        WindowGroup {
            ZStack {
                HStack(spacing: 0) {
#if !os(macOS)

                    if self.isDrawerOpen {
                        DrawerContent(settingsViewModel: settingsViewModel, isDrawerOpen: $isDrawerOpen, conversations: $settingsViewModel.conversations, isPortrait: $isPortrait)
                            .environmentObject(appState)
                            .environmentObject(WindowManager.shared)
                            .transition(.move(edge: .leading))
                            .background(settingsViewModel.buttonColor)
                            .frame(minWidth: isPortrait ? drawerWidth : drawerWidthLandscape, maxWidth: isPortrait ? drawerWidth : drawerWidthLandscape, minHeight: 0, maxHeight: .infinity)
                    }
#endif
                    ContentView(settingsViewModel: settingsViewModel, isDrawerOpen: $isDrawerOpen)
                        .environmentObject(appState)
                }
                .overlay(
                    Group {
                        if settingsViewModel.showInstructions {
                            InstructionsPopup(isPresented: $settingsViewModel.showInstructions ,settingsViewModel: settingsViewModel)
                        }
                    }
                )

                .onAppear {
#if !os(macOS)

                    SwiftSageiOSAppDelegate.applicationDidFinishLaunching()
#endif

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        serviceDiscovery?.startDiscovering()
                    }
#if !os(macOS)

                    consoleManager.fontSize = settingsViewModel.textSize
#endif
                    DispatchQueue.main.async {
#if !os(macOS)

                        isPortrait = UIApplication.shared.statusBarOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown
#endif
                        settingsViewModel.printVoicesInMyDevice()
                        settingsViewModel.configureAudioSession()
                    }

                }
#if !os(macOS)
                .onAppear {
                    guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
                    self.isPortrait = scene.interfaceOrientation.isPortrait
                }

                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                    guard let scene = UIApplication.shared.windows.first?.windowScene else { return }
                    self.isPortrait = scene.interfaceOrientation.isPortrait
                }
#endif
#if !os(macOS)

                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification)) { _ in
                        logD("didFinishLaunchingNotification")
                        SwiftSageiOSAppDelegate.applicationDidFinishLaunching()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        logD("applicationDidBecomeActive")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        logD("applicationWillEnterForeground")

                        screamer.discoReconnect()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        logD("didEnterBackgroundNotification")
                        SwiftSageiOSAppDelegate.applicationDidEnterBackground()
                    }
#endif
            }

        }
    }
}
func setHasSeenInstructions(_ hasSeen: Bool) {
    UserDefaults.standard.set(hasSeen, forKey: "hasSeenInstructions")
}
func hasSeenInstructions() -> Bool {
    return UserDefaults.standard.bool(forKey: "hasSeenInstructions")
}
class AppState: ObservableObject {
    @Published var isInBackground: Bool = false
    private var cancellables: [AnyCancellable] = []

    init() {
#if !os(macOS)
    //        let didEnterBackground = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
    //            .map { _ in true }
    //            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    //            .removeDuplicates()
    //
    //        let willEnterForeground = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    //            .map { _ in false }
    //            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    //            .removeDuplicates()
    //
    //        didEnterBackground
    //            .merge(with: willEnterForeground)
    //            .sink { [weak self] in
    //                self?.isInBackground = $0
    //                DispatchQueue.main.asyncAfter(deadline: .now() + reconnectInterval) {
    //                        serviceDiscovery?.startDiscovering()
    //                }
    //            }
    //            .store(in: &cancellables)
#endif
    }
}
