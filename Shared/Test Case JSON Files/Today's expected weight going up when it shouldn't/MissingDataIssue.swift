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
    static func missingDataIssue() -> some View {
        MainPreview(options: .init([ .isMissingConsumedCalories(true), .testCase(.missingDataIssue)]))
    }
}

#Preview("Missing calories v3") {
    FitnessPreviewProvider.missingDataIssue()
}

