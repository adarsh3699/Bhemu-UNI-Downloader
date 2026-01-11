//
//  DiskSpaceChecker.swift
//  Bhemu UNI Downloader
//
//  Description: Utility to check available disk space before downloads
//

import Foundation

/// Provides disk space checking functionality
struct DiskSpaceChecker {
    
    /// Minimum required free space in bytes (500 MB)
    static let minimumFreeSpace: Int64 = 500 * 1024 * 1024
    
    /// Checks if there's enough disk space at the specified path
    /// - Parameter url: The directory URL to check
    /// - Returns: Tuple containing (hasSpace, freeSpace in GB, totalSpace in GB)
    static func checkDiskSpace(at url: URL) -> (hasSpace: Bool, freeGB: Double, totalGB: Double) {
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            
            let availableSpace = values.volumeAvailableCapacityForImportantUsage ?? 0
            let totalSpace = values.volumeTotalCapacity ?? 0
            
            let freeGB = Double(availableSpace) / 1_073_741_824 // Convert to GB
            let totalGB = Double(totalSpace) / 1_073_741_824
            
            let hasSpace = availableSpace > minimumFreeSpace
            
            return (hasSpace, freeGB, totalGB)
        } catch {
            print("⚠️ Error checking disk space: \(error)")
            // Assume there's space if we can't check
            return (true, 0, 0)
        }
    }
    
    /// Returns a user-friendly message about disk space
    /// - Parameter url: The directory URL to check
    /// - Returns: Optional error message if space is low, nil if sufficient
    static func getDiskSpaceWarning(at url: URL) -> String? {
        let (hasSpace, freeGB, _) = checkDiskSpace(at: url)
        
        if !hasSpace {
            return "Low disk space: Only \(String(format: "%.2f", freeGB)) GB available. Please free up space before downloading."
        }
        
        if freeGB < 1.0 {
            return "Warning: Less than 1 GB free space available. Download may fail for large files."
        }
        
        return nil
    }
    
    /// Formats bytes to human-readable string
    /// - Parameter bytes: Number of bytes
    /// - Returns: Formatted string (e.g., "2.5 GB")
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
