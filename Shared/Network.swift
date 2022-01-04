//
//  Network.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 12/24/21.
//

import Foundation

class Network {
    let urlString = "https://tommys-fitness.herokuapp.com/api/fitness/"
    
    func get() async -> DataToReceive {
        return await withUnsafeContinuation { continuation in
            guard let url = URLComponents(string: urlString)?.url else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                guard error == nil, let data = data else { return }
                if let dataReceived = try? JSONDecoder().decode(DataToReceive.self, from: data) {
                    continuation.resume(returning: dataReceived)
                }
            })
            task.resume()
        }
    }
    
    func post<T: Codable>(object: T) async -> DataToReceive { // todo change to put
        return await withUnsafeContinuation { continuation in
            guard let url = URLComponents(string: urlString)?.url else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST" // todo change to put
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            do {
                let encodedData = try JSONEncoder().encode(object)
                request.httpBody = encodedData
            } catch { return }
            
            let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                guard error == nil, let data = data else { return }
                if let networkPostResponse = try? JSONDecoder().decode(DataToReceive.self, from: data) {
                    continuation.resume(returning: networkPostResponse)
                }
            })
            task.resume()
        }
    }
}
