//
//  ChartContentExtension.swift
//  Fitness
//
//  Created by Thomas on 5/31/24.
//

import SwiftUI
import Charts

extension ChartContent {
    @ChartContentBuilder
    func conditional<Content: ChartContent>(_ condition: Bool, transform: (Self) -> Content) -> some ChartContent {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ChartContentBuilder
    func overlayPointWith(text: String) -> some ChartContent {
        self.annotation(position: .overlay, alignment: .bottom, spacing: 5) {
            Text(text)
                .foregroundStyle(.yellow)
                .fontWeight(.light)
                .font(.system(size: 10))
        }
    }
}
