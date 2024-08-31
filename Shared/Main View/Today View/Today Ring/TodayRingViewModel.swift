//
//  TodayRingViewModel.swift
//  Fitness
//
//  Created by Thomas on 3/31/23.
//

import Foundation

public struct TodayRingViewModel: Hashable, Identifiable {
    public static func == (lhs: TodayRingViewModel, rhs: TodayRingViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id: UUID = UUID()
    var titleText: String
    var bodyText: String
    var subBodyText: String
    var percentage: Decimal
    var color: TodayRingColor = .yellow
    var bodyTextColor: TodayRingColor = .white
    var subBodyTextColor: TodayRingColor = .white
    var gradient: [TodayRingColor]?
    var lineWidth: CGFloat = 10
    var fontSize: CGFloat = 40
    var includeTitle: Bool = true
    var includeSubBody: Bool = true
    var shouldPad: Bool = true
}
