//
//  NetworkClient.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/23.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

protocol NetworkClientProtocol {

    func getData(at url: URL, completion: @escaping ((Data) -> Void), failure: @escaping ((Error) -> Void))
}

class NetworkClient: NetworkClientProtocol {

    static let `default` = NetworkClient()

    func getData(at url: URL, completion: @escaping ((Data) -> Void), failure: @escaping ((Error) -> Void)) {
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            DispatchQueue.main.async {
                if let data = data {
                    return completion(data)
                }
                else if let error = error {
                    failure(error)
                } else {
                    return completion(Data())
                }
            }
        }
        task.resume()
    }
}
