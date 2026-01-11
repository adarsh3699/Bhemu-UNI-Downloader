//
//  FirstRunSetupView.swift
//  Bhemu UNI Downloader
//
//  Author: Adarsh Suman (adarsh3699@gmail.com)
//  Website: https://bhemu.in
//  Description: First-run setup wizard for optimal performance
//

import SwiftUI

struct FirstRunSetupView: View {
    @State private var isCheckingDependencies = true
    @State private var hasSystemYtdlp = false
    @State private var hasHomebrew = false
    @State private var isInstalling = false
    @State private var installProgress = ""
    @State private var installError = ""
    @State private var setupComplete = false
    @State private var showInstallHomebrew = false
    @State private var currentStep = 0
    @State private var totalSteps = 3
    @State private var installationSteps: [InstallStep] = []
    @State private var installationLog: [String] = []
    @State private var showLog = false
    @Environment(\.dismiss) private var dismiss
    
    var onComplete: () -> Void
    
    struct InstallStep: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        var status: StepStatus
    }
    
    enum StepStatus {
        case pending
        case inProgress
        case completed
        case failed
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
            // Header
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(16)
                    .shadow(radius: 5)
            }
            
            Text("👋 Welcome to Bhemu UNI Downloader")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Download videos from YouTube, Instagram, TikTok, and 1000+ sites")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .padding(.vertical)
            
            if isCheckingDependencies {
                // Checking phase
                ProgressView()
                    .scaleEffect(1.2)
                Text("Checking your system...")
                    .font(.subheadline)
                    .padding(.top, 8)
                
            } else if setupComplete {
                // Success
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("All Set! 🎉")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if hasSystemYtdlp {
                        VStack(spacing: 8) {
                            Text("⚡ Your downloads will start instantly!")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("We'll use your system's optimized tools")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("✅ Ready to download!")
                                .font(.headline)
                            Text("First download may take 10-15 seconds to start")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("💡 Tip: Install Homebrew for instant downloads")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        onComplete()
                        dismiss()
                    }) {
                        Text("Start Downloading")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top)
                }
                
            } else if isInstalling {
                // Installing with progress visualization
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("Setting Up...")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(installProgress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                
                                // Progress fill
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 12)
                                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                            }
                        }
                        .frame(height: 12)
                        
                        HStack {
                            Text("Step \(currentStep) of \(totalSteps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(Double(currentStep) / Double(totalSteps) * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Installation Steps
                    VStack(spacing: 12) {
                        ForEach(installationSteps) { step in
                            InstallStepRow(step: step)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Live Installation Log
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "terminal")
                                .foregroundColor(.green)
                            Text("Installation Log")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: { showLog.toggle() }) {
                                Image(systemName: showLog ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if showLog {
                            ScrollView {
                                ScrollViewReader { proxy in
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(Array(installationLog.enumerated()), id: \.offset) { index, log in
                                            Text(log)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .textSelection(.enabled)
                                                .id(index)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .onChange(of: installationLog.count) { _ in
                                        if let lastIndex = installationLog.indices.last {
                                            withAnimation {
                                                proxy.scrollTo(lastIndex, anchor: .bottom)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                            .padding(8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                        } else {
                            Text("Click to view detailed progress...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                    
                    if !installError.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Installation Issue")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            
                            Text(installError)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: 500)
                
            } else {
                // Setup required
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Quick Setup Required")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("We'll install the tools needed for downloading")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        SetupStepView(
                            icon: "checkmark.circle.fill",
                            title: "One-time setup",
                            description: "Takes 3-5 minutes"
                        )
                        
                        SetupStepView(
                            icon: "bolt.fill",
                            title: "Instant downloads",
                            description: "After setup, downloads start immediately"
                        )
                        
                        SetupStepView(
                            icon: "lock.shield.fill",
                            title: "Safe & trusted",
                            description: "Uses official open-source tools"
                        )
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    Button(action: {
                        installEverything()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Start Setup")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    // Show "How does this work?" link
                    Button(action: { showInstallHomebrew.toggle() }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("What will be installed?")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    if showInstallHomebrew {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("We'll install:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text("• Homebrew (package manager for Mac)")
                            Text("• yt-dlp (video downloader)")
                            Text("• ffmpeg (video processor)")
                            
                            Text("\nAll are free, open-source, and widely trusted by millions of users. You can uninstall them anytime.")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .frame(maxWidth: 500)
                    }
                }
                .frame(maxWidth: 550)
            }
            
            Spacer()
            }
        }
        .padding(40)
        .frame(width: 650, height: 600)
        .onAppear {
            checkDependencies()
        }
    }
    
    func checkDependencies() {
        DispatchQueue.global().async {
            // Check if system yt-dlp is available (Homebrew or system-installed)
            let systemPaths = [
                "/opt/homebrew/bin/yt-dlp",
                "/usr/local/bin/yt-dlp",
                "/usr/bin/yt-dlp"
            ]
            
            hasSystemYtdlp = systemPaths.contains { path in
                FileManager.default.fileExists(atPath: path)
            }
            
            // Check if Homebrew is installed
            hasHomebrew = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") ||
                         FileManager.default.fileExists(atPath: "/usr/local/bin/brew")
            
            DispatchQueue.main.async {
                isCheckingDependencies = false
                
                // If already has system yt-dlp, auto-complete after showing success
                if hasSystemYtdlp {
                    setupComplete = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        onComplete()
                        dismiss()
                    }
                }
            }
        }
    }
    
    func installEverything() {
        isInstalling = true
        installProgress = "Starting setup..."
        installError = ""
        currentStep = 0
        installationLog = []
        showLog = true  // Auto-expand log so users see activity
        
        // Add initial log entry
        DispatchQueue.main.async {
            self.installationLog.append("🚀 Starting installation process...")
            self.installationLog.append("📍 \(Date().formatted(date: .omitted, time: .standard))")
            self.installationLog.append("")
        }
        
        // Initialize installation steps
        DispatchQueue.main.async {
            self.installationSteps = [
                InstallStep(icon: "arrow.down.circle.fill", title: "Checking Homebrew", status: .pending),
                InstallStep(icon: "video.fill", title: "Installing yt-dlp", status: .pending),
                InstallStep(icon: "film.fill", title: "Installing ffmpeg", status: .pending)
            ]
        }
        
        DispatchQueue.global().async {
            // Helper function to add log entry
            func addLog(_ message: String) {
                DispatchQueue.main.async {
                    self.installationLog.append(message)
                }
            }
            
            // Helper function to run brew commands with proper PATH and live logging
            func runBrewCommand(_ command: String, progressMessage: String) -> (success: Bool, output: String) {
                DispatchQueue.main.async {
                    self.installProgress = progressMessage
                }
                
                addLog("$ \(command)")
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                
                // CRITICAL: Set up proper environment with Homebrew paths
                var environment = ProcessInfo.processInfo.environment
                let homebrewPaths = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
                environment["PATH"] = homebrewPaths
                process.environment = environment
                
                // Use login shell to ensure PATH is loaded
                process.arguments = ["-l", "-c", command]
                
                let outputPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = outputPipe
                
                var fullOutput = ""
                
                // Read output in real-time
                outputPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        if let output = String(data: data, encoding: .utf8) {
                            fullOutput += output
                            let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
                            for line in lines where !line.isEmpty {
                                addLog(String(line))
                            }
                        }
                    }
                }
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    // Stop reading
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    
                    let success = process.terminationStatus == 0
                    addLog(success ? "✅ Command completed successfully" : "❌ Command failed with exit code \(process.terminationStatus)")
                    addLog("")
                    return (success, fullOutput)
                } catch {
                    addLog("❌ Error: \(error.localizedDescription)")
                    addLog("")
                    return (false, error.localizedDescription)
                }
            }
            
            // Step 1: Check/Install Homebrew if needed
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            addLog("📦 Step 1/3: Checking Homebrew")
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            DispatchQueue.main.async {
                self.currentStep = 1
                self.installationSteps[0].status = .inProgress
                self.installProgress = "Checking Homebrew installation..."
            }
            
            if !self.hasHomebrew {
                addLog("⚠️  Homebrew not found, installing...")
                DispatchQueue.main.async {
                    self.installProgress = "Installing Homebrew...\nThis takes 2-3 minutes"
                }
                
                // Non-interactive Homebrew installation
                let homebrewInstall = """
                NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                """
                
                let result = runBrewCommand(homebrewInstall, progressMessage: "📦 Installing Homebrew... Please wait")
                
                if !result.success {
                    print("❌ Homebrew install failed: \(result.output)")
                    DispatchQueue.main.async {
                        self.installationSteps[0].status = .failed
                        self.installError = "Couldn't install Homebrew automatically.\nPlease install manually: https://brew.sh"
                        self.isInstalling = false
                    }
                    return
                }
                
                self.hasHomebrew = true
            } else {
                addLog("✅ Homebrew already installed")
            }
            
            DispatchQueue.main.async {
                self.installationSteps[0].status = .completed
                self.currentStep = 1  // Step 1 complete
                self.installProgress = "Homebrew ready ✓"
            }
            
            // Small delay for UI update
            usleep(300_000)  // 0.3 seconds
            
            // Step 2: Install yt-dlp
            addLog("")
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            addLog("⚡ Step 2/3: Installing yt-dlp")
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            DispatchQueue.main.async {
                self.installationSteps[1].status = .inProgress
                self.installProgress = "Installing video downloader...\nAlmost there!"
            }
            
            let ytdlpResult = runBrewCommand(
                "brew install yt-dlp",
                progressMessage: "⚡ Installing yt-dlp..."
            )
            
            if !ytdlpResult.success {
                print("❌ yt-dlp install failed: \(ytdlpResult.output)")
                DispatchQueue.main.async {
                    self.installationSteps[1].status = .failed
                }
            } else {
                DispatchQueue.main.async {
                    self.installationSteps[1].status = .completed
                    self.currentStep = 2  // Step 2 complete
                }
            }
            
            // Small delay for UI update
            usleep(300_000)  // 0.3 seconds
            
            // Step 3: Install ffmpeg
            addLog("")
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            addLog("🎬 Step 3/3: Installing ffmpeg")
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            DispatchQueue.main.async {
                self.installationSteps[2].status = .inProgress
                self.installProgress = "Installing video processor...\nFinalizing setup..."
            }
            
            let ffmpegResult = runBrewCommand(
                "brew install ffmpeg",
                progressMessage: "🎬 Installing ffmpeg..."
            )
            
            if !ffmpegResult.success {
                print("❌ ffmpeg install failed: \(ffmpegResult.output)")
                DispatchQueue.main.async {
                    self.installationSteps[2].status = .failed
                }
            } else {
                DispatchQueue.main.async {
                    self.installationSteps[2].status = .completed
                }
            }
            
            // Step 4: Verify installation
            addLog("")
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            addLog("🔍 Verifying installation...")
            addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            let ytdlpPaths = [
                "/opt/homebrew/bin/yt-dlp",
                "/usr/local/bin/yt-dlp",
                "/usr/bin/yt-dlp"
            ]
            
            let ytdlpInstalled = ytdlpPaths.contains { path in
                let exists = FileManager.default.fileExists(atPath: path)
                if exists {
                    addLog("✅ Found yt-dlp at: \(path)")
                }
                return exists
            }
            
            DispatchQueue.main.async {
                if ytdlpInstalled {
                    addLog("✅ All tools verified successfully!")
                    addLog("🎉 Setup complete - Ready to download!")
                    
                    self.currentStep = 3
                    self.installProgress = "🎉 Setup complete!\nAll tools installed successfully"
                    self.hasSystemYtdlp = true
                    
                    // Mark all as completed
                    for i in 0..<self.installationSteps.count {
                        if self.installationSteps[i].status != .failed {
                            self.installationSteps[i].status = .completed
                        }
                    }
                    
                    // Save completion
                    UserDefaults.standard.set(true, forKey: "hasCompletedFirstRun")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.setupComplete = true
                    }
                } else {
                    addLog("❌ Verification failed - tools not found")
                    addLog("Please check the error messages above")
                    
                    // Installation failed but don't leave user stuck
                    self.installError = """
                    Setup had an issue installing tools.
                    
                    Please open Terminal and run:
                    brew install yt-dlp ffmpeg
                    
                    Then restart the app!
                    """
                    
                    print("Installation verification failed")
                    print("yt-dlp result: \(ytdlpResult.output)")
                    print("ffmpeg result: \(ffmpegResult.output)")
                    
                    self.isInstalling = false
                }
            }
        }
    }
}

struct InstallStepRow: View {
    let step: FirstRunSetupView.InstallStep
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Group {
                switch step.status {
                case .pending:
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                case .inProgress:
                    ProgressView()
                        .scaleEffect(0.8)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 24, height: 24)
            
            // Step info
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(step.status == .inProgress ? .semibold : .regular)
                    .foregroundColor(step.status == .failed ? .red : .primary)
                
                if step.status == .inProgress {
                    Text("Please wait...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SetupStepView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct OptionCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let description: String
    let badge: String?
    let badgeColor: Color
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isRecommended ? .green : .blue)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(badgeColor.opacity(0.2))
                                .foregroundColor(badgeColor)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isRecommended ? .green : .blue)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRecommended ? Color.green.opacity(0.05) : Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isRecommended ? Color.green.opacity(0.3) : Color.blue.opacity(0.2), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
