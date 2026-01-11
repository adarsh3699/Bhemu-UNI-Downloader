//
//  BhemuUNIDownloaderApp.swift
//  Bhemu UNI Downloader
//
//  Created: 2026
//  Author: Adarsh Suman (adarsh3699@gmail.com)
//  Website: https://bhemu.in
//  Description: Universal video downloader for macOS
//

import SwiftUI

@main
struct BhemuUNIDownloaderApp: App {
    @AppStorage("hasCompletedFirstRun") private var hasCompletedFirstRun = false
    @State private var showFirstRunSetup = false
    
    init() {
        // Check if dependencies are missing on launch
        let ytdlpPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        
        let hasDependencies = ytdlpPaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }
        
        // If dependencies are missing, reset first-run flag to show setup
        if !hasDependencies {
            UserDefaults.standard.set(false, forKey: "hasCompletedFirstRun")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .frame(minWidth: 700, minHeight: 600)
                
                // Show first-run setup as overlay
                if showFirstRunSetup {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    FirstRunSetupView {
                        hasCompletedFirstRun = true
                        showFirstRunSetup = false
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(16)
                    .shadow(radius: 20)
                }
            }
            .onAppear {
                // Show setup on first run
                if !hasCompletedFirstRun {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showFirstRunSetup = true
                    }
                }
            }
        }
        .windowStyle(.automatic)
        .commands {
            // Remove default "New Window" command
            CommandGroup(replacing: .newItem) {}
            
            // Add Help command
            CommandGroup(replacing: .help) {
                HelpMenuButton()
            }
        }
        
        // Help Window
        Window("Help", id: "help") {
            HelpView()
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}

// Helper view for Help menu button
struct HelpMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button("Bhemu UNI Downloader Help") {
            openWindow(id: "help")
        }
        .keyboardShortcut("?", modifiers: .command)
    }
}
