//
//  ListService.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 Interface to the item list data.
 */
class ListCache {

    /**
     Shared instance.
     */
    static let `default` = ListCache()

    /**
     Cached list items.

     Initially empty, call fetchList(completion:failure:) at list once before queying this property's
     value.
     */
    private(set) public var cache: [VideoDescriptor] = []

    /**
     For use on initial load: calls refreshList(completion:failure:) only if the cache is empty.
     */
    func fetchList(completion: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) {
        guard cache.isEmpty else {
            return completion()
        }
        refreshList(completion: completion, failure: failure)
    }

    /**
     Retrieves the latest data.
     */
    func refreshList(completion: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) {
        ListService.default.fetchList(at: nil, completion: { [weak self](list) in
            self?.cache = list
            completion()
            
        }, failure: failure)
    }

}

// MARK: - Supporting Types

/**
 Private class in charge of downloading the list over the network. Use `ListCache` instead,
 which leverages `ListService` if needed.
 */
private class ListService {

    static let `default` = ListService()

    func fetchList(at url: URL? = nil, completion: @escaping (([VideoDescriptor]) -> Void), failure: @escaping ((Error) -> Void)) {
        /*
         Using  Dummy local data for this demo:
         */
        guard let jsonURL = Bundle.main.url(forResource: "DummyData", withExtension: "json") else {
            return failure(ListServiceError.dummyResourceNotFound)
        }
        guard let data = try? Data(contentsOf: jsonURL) else {
            return failure(ListServiceError.dummyDataCorrupted)
        }
        do {
            let list = try JSONDecoder().decode([VideoDescriptor].self, from: data)
            return completion(list)
        } catch {
            return failure(error)
        }
    }
}

enum ListServiceError: LocalizedError {

    case dummyResourceNotFound

    case dummyDataCorrupted

    var localizedDescription: String {
        switch self {
        case .dummyDataCorrupted:
            return "Dummy JSON resource is corrupted."

        case .dummyResourceNotFound:
            return "Dummy JSON resource is missing."
        }
    }
}
