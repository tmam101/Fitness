//
//  NetworkModel.swift
//  Fitness (iOS)
//
//  Created by Thomas Goss on 12/24/21.
//

import Foundation

struct NetworkModelPost: Codable {
    var d: NetworkModel
}
// MARK: - NetworkModelResponse
struct NetworkModel: Codable {
    let deficitToday, averageDeficitThisWeek, averageDeficitThisMonth: Int
}

//typealias NetworkModel = [NetworkModelElement]

// MARK: - NetworkModelResponse
struct NetworkPostResponse: Codable {
    let message: String
    let data: DataToReceive
}

// MARK: - DataClass
struct DataClass: Codable {
    let deficitToday, averageDeficitThisWeek, averageDeficitThisMonth: Int
}
