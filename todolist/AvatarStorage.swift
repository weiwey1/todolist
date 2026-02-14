//
//  AvatarStorage.swift
//

import Foundation
import UIKit

actor AvatarStorage {
    static let shared = AvatarStorage()

    private var cachedImage: UIImage?
    private var cachedURL: URL?

    func loadImage() -> UIImage? {
        guard let url = try? avatarFileURL() else { return nil }
        if let cachedImage, cachedURL == url {
            return cachedImage
        }
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            cachedImage = nil
            cachedURL = nil
            return nil
        }
        cachedImage = image
        cachedURL = url
        return image
    }

    func save(imageData: Data) throws -> URL {
        let url = try avatarFileURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try imageData.write(to: url, options: [.atomic])
        cachedImage = UIImage(data: imageData)
        cachedURL = url
        return url
    }

    func delete() throws {
        let url = try avatarFileURL()
        if FileManager.default.fileExists(atPath: url.path()) {
            try FileManager.default.removeItem(at: url)
        }
        cachedImage = nil
        cachedURL = nil
    }

    func avatarFileURL() throws -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = baseURL.appendingPathComponent("todolist/profile", isDirectory: true)
        return directory.appendingPathComponent("avatar.jpg")
    }
}
