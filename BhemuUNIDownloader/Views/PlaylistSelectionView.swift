//
//  PlaylistSelectionView.swift
//  Bhemu UNI Downloader
//
//  Author: Adarsh Suman (adarsh3699@gmail.com)
//  Website: https://bhemu.in
//  Description: View for selecting videos from a playlist
//

import SwiftUI

struct PlaylistSelectionView: View {
    @StateObject private var viewModel = PlaylistViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let playlistURL: String
    let onDownload: ([PlaylistItem], DownloadQuality, URL) -> Void
    
    @State private var selectedQuality: DownloadQuality = .p1080
    @State private var outputDirectory: URL
    
    init(playlistURL: String, outputDirectory: URL, onDownload: @escaping ([PlaylistItem], DownloadQuality, URL) -> Void) {
        self.playlistURL = playlistURL
        self.onDownload = onDownload
        self._outputDirectory = State(initialValue: outputDirectory)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
                .background(Color(.windowBackgroundColor))
            
            Divider()
            
            if viewModel.isLoading {
                ProgressView("Loading playlist...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.videos.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
        .frame(width: 700, height: 600)
        .task {
            await viewModel.fetchPlaylist(url: playlistURL)
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "list.bullet.rectangle")
                .font(.title)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Playlist Selection")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(viewModel.videos.count) videos · \(viewModel.selectedCount) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 16) {
            // Selection controls
            selectionControlsView
                .padding(.horizontal)
                .padding(.top)
            
            Divider()
            
            // Video list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                        videoRow(video: video, index: index + 1)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Download options
            downloadOptionsView
                .padding()
                .background(Color(.windowBackgroundColor))
        }
    }
    
    private var selectionControlsView: some View {
        HStack(spacing: 12) {
            Button("Select All") {
                viewModel.selectAll()
            }
            
            Button("Deselect All") {
                viewModel.deselectAll()
            }
            
            Spacer()
            
            Text("Range:")
                .foregroundColor(.secondary)
            
            TextField("e.g., 1-10", text: $viewModel.rangeInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            
            Button("Apply") {
                viewModel.applyRange()
            }
        }
    }
    
    private func videoRow(video: PlaylistItem, index: Int) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { video.isSelected },
                set: { _ in viewModel.toggleSelection(for: video.id) }
            ))
            .toggleStyle(.checkbox)
            
            Text("\(index).")
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .lineLimit(2)
                
                Text(video.durationFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(video.isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
    
    private var downloadOptionsView: some View {
        HStack(spacing: 16) {
            Label("Quality:", systemImage: "film")
                .font(.headline)
            
            Picker("Quality", selection: $selectedQuality) {
                ForEach(DownloadQuality.allCases) { quality in
                    Text(quality.rawValue).tag(quality)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)
            
            Spacer()
            
            Button("Download Selected (\(viewModel.selectedCount))") {
                onDownload(viewModel.selectedVideos, selectedQuality, outputDirectory)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedCount == 0)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error Loading Playlist")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Close") {
                dismiss()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Videos Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The playlist appears to be empty")
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
