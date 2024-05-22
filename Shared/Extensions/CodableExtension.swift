//
//  CodableExtension.swift
//  Fitness
//
//  Created by Thomas on 5/16/24.
//

import Foundation

extension Decodable {
    fileprivate static func decodeFromFile<T: Decodable>(path: String) -> T? {
        guard
            let path = Bundle.main.path(forResource: path, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let jsonResult = try? JSONDecoder().decode(T.self, from: data)
        else {
            return nil
        }
        return jsonResult
    }
}

enum Filepath {
    enum Double: String {
        case activeCalories
        case restingCalories
        case consumedCalories
        case upAndDownWeights
        case missingConsumedCalories
        case weightGoingSteadilyDown
    }
    enum Days: String {
        case missingDataIssue
        case realisticWeightsIssue
    }
}

extension Array where Element == Double {
    static func decode(path: Filepath.Double) -> [Double]? {
        return decodeFromFile(path: path.rawValue)
    }
}

extension Days  {
    static func decode(path: Filepath.Days) -> Days? {
        return decodeFromFile(path: path.rawValue)
    }
}

extension Encodable {
    func encodeAsString() -> String {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        guard
            let jsonData = try? jsonEncoder.encode(self),
            let json = String(data: jsonData, encoding: String.Encoding.utf8) else {
            return "Failed"
        }
        return json
    }
    
    func encode() -> Data? {
        let jsonEncoder = JSONEncoder()
        guard
            let jsonData = try? jsonEncoder.encode(self) else {
            return nil
        }
        return jsonData
    }
}

struct Decoder<T: Codable> {
    static func decode(path: String) -> T? {
        guard
            let path = Bundle.main.path(forResource: path, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let jsonResult = try? JSONDecoder().decode(T.self, from: data)
        else {
            return nil
        }
        return jsonResult
    }
}
