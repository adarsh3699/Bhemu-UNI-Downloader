//
//  DownloadState.swift
//  Bhemu UNI Downloader
//
//  Description: Represents the current state of the download process
//

import Foundation

enum DownloadState: Equatable {
    case idle
    case running
    case paused
    case completed
    case failed(String)
    case cancelled
    case retrying(attempt: Int)
    
    var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }
    
    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }
    
    var canResume: Bool {
        if case .paused = self {
            return true
        }
        return false
    }
    
    var isRetrying: Bool {
        if case .retrying = self {
            return true
        }
        return false
    }
}
