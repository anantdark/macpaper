// Copyright (C) 2026 macpaper contributors
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import Foundation

/// Minimal helper: create a Tahoe wallpaper image-folder entry blob (binary plist).
/// Usage:
///   ImageFolderHelper entry <folderPath>
/// Prints base64-encoded entry Data on stdout.

enum Mode: String {
    case entry
}

func cacheBasePath() throws -> String {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/getconf")
    task.arguments = ["DARWIN_USER_CACHE_DIR"]
    let pipe = Pipe()
    task.standardOutput = pipe
    try task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard var path = String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !path.isEmpty else {
        throw NSError(domain: "macpaper", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Could not resolve DARWIN_USER_CACHE_DIR"
        ])
    }
    if path.hasPrefix("/var/") {
        path = "/private" + path
    }
    if !path.hasSuffix("/") {
        path += "/"
    }
    return path
}

func makeFolderEntry(folderPath: String) throws -> Data {
    var path = (folderPath as NSString).standardizingPath
    if !path.hasSuffix("/") {
        path += "/"
    }

    let folderURL = URL(fileURLWithPath: path, isDirectory: true)
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
        throw NSError(domain: "macpaper", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Not a directory: \(folderPath)"
        ])
    }

    let entryID = UUID().uuidString.uppercased()
    let cloneID = UUID().uuidString.uppercased()
    let cache = try cacheBasePath()
    let cloneURLString = "file://\(cache)com.apple.wallpaper.extension.image/\(cloneID)/"

    let bookmarkData = try folderURL.bookmarkData(
        options: [.minimalBookmark],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
    )

    // Key insertion order matters for binary plist compatibility with WallpaperAgent.
    let ordered = NSMutableDictionary()
    ordered["id"] = entryID
    ordered["dateAdded"] = Date()
    ordered["originalURL"] = ["relative": folderURL.absoluteString]
    ordered["originalURLBookmarkData"] = bookmarkData
    ordered["cloneURL"] = ["relative": cloneURLString]

    return try PropertyListSerialization.data(
        fromPropertyList: ordered,
        format: .binary,
        options: 0
    )
}

let args = CommandLine.arguments
guard args.count >= 3, let mode = Mode(rawValue: args[1]) else {
    fputs("usage: ImageFolderHelper entry <folderPath>\n", stderr)
    exit(2)
}

do {
    switch mode {
    case .entry:
        let data = try makeFolderEntry(folderPath: args[2])
        print(data.base64EncodedString())
    }
} catch {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
