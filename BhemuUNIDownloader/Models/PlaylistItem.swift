//
//  PlaylistItem.swift
//  Bhemu UNI Downloader
//
//  Description: Model representing a single video in a playlist
//

import Foundation

struct PlaylistItem: Identifiable, Codable {
    let id: String
    let title: String
    let duration: Int?
    let url: String
    let thumbnail: String?
    var isSelected: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case duration
        case url
        case thumbnail
    }
    
    var durationFormatted: String {
        guard let duration = duration else { return "Unknown" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlaylistInfo: Codable {
    let title: String
    let uploader: String?
    let entries: [PlaylistEntry]
    
    struct PlaylistEntry: Codable {
        let id: String
        let title: String
        let duration: Int?
        let url: String?
        let thumbnail: String?
    }
}
