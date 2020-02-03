//
//  VideoDescriptor.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Represents **one** video item in the JSON list retrieved from the server.
 */
class VideoDescriptor: Decodable {

    ///
    let title: String

    ///
    let presenterName: String

    ///
    let description: String

    ///
    let thumbURL: URL

    ///
    let videoURL: URL

    ///
    let duration: Double

    // MARK: - Decodable

    enum CodingKeys: String, CodingKey {
        case title
        case presenterName = "presenter_name"
        case description
        case thumbURLString = "thumbnail_url"
        case videoURLString = "video_url"
        case duration = "video_duration"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.decode(String.self, forKey: .title)
        self.presenterName = try container.decode(String.self, forKey: .presenterName)
        self.description = try container.decode(String.self, forKey: .description)

        let thumbURLString = try container.decode(String.self, forKey: .thumbURLString)
        guard let thumbURL = URL(string: thumbURLString) else {
            throw VideoDescriptorError.invalidURLString
        }
        self.thumbURL = thumbURL

        let videoURLString = try container.decode(String.self, forKey: .videoURLString)
        guard let videoURL = URL(string: videoURLString) else {
            throw VideoDescriptorError.invalidURLString
        }
        self.videoURL = videoURL
        self.duration = try container.decode(Double.self, forKey: .duration)
    }
}

// MARK: - Supporting Types

enum VideoDescriptorError: LocalizedError {
    case invalidURLString

    var localizedDescription: String {
        switch self {
        case .invalidURLString:
            return "String does not represent a valid URL"
        }
    }
}
