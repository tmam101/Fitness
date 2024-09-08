//
//  RealisticWeightsIssue.swift
//  Fitness
//
//  Created by Thomas on 5/22/24.
//

import SwiftUI

#Preview("Realistic weights issue") {
    FitnessPreviewProvider.MainPreview(
        options: .init([
            .testCase(.realisticWeightsIssue),
            .isMissingConsumedCalories(.v3)
//            .subsetOfDays(63, 55)
        ]))
}
