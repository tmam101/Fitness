//
//  MissingDataIssue.swift
//  Fitness (iOS)
//
//  Created by Thomas on 5/3/24.
//

import SwiftUI

/* In this issue:
 Today is Thursday. (0 days ago). No data was entered.
 Yesterday, Wednesday, 1 day ago, no data was entered.
 */

extension FitnessPreviewProvider {
    static func missingDataIssue(_ strategy: TestDayOption.MissingConsumedCaloriesStrategy) -> some View {
        MainPreview(options: [ .isMissingConsumedCalories(strategy), .testCase(.missingDataIssue)])
    }
}

#Preview("Missing calories v1") {
    FitnessPreviewProvider.missingDataIssue(.v1)
}

#Preview("Missing calories v2") {
    FitnessPreviewProvider.missingDataIssue(.v2)
}

#Preview("Missing calories v3") {
    FitnessPreviewProvider.missingDataIssue(.v3)
}

