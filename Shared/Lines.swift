//
//  Lines.swift
//  Fitness
//
//  Created by Thomas Goss on 1/26/21.
//

import SwiftUI
import HealthKit

//struct ChartBody: View {
//@State var data: [Double]
//var body: some View {
//    GeometryReader { geometry in
//        Path { path in
//            path.move(to: .init(x: 0, y: geometry.size.height))
//
//            self.data.forEach { point in
//                let x = (point.x / self.maxXValue) * geometry.size.width
//                let y = geometry.size.height - (point.y / self.maxYValue) * geometry.size.height
//                
//                path.addLine(to: .init(x: x, y: y))
//            }
//        }
//        .stroke(
//            Color.black,
//            style: StrokeStyle(lineWidth: 3)
//        )
//  }
//}
//}

struct Lines: View {
    @EnvironmentObject var myHealth: MyHealthKit
        
    var body: some View {
//        LineView(data: myHealth.weights?.map { $0.quantity.doubleValue(for: HKUnit.pound()) } ?? [232.0, 230.0, 230.2, 231.8])
        LineView(data: [232.0, 230.0, 230.2, 231.8])
    }
}


struct Lines_Previews: PreviewProvider {
    static var previews: some View {
        Lines().environmentObject(MyHealthKit())
    }
}

struct LineView: View {
    @State var data: [(Double)]
    var title: String?
    var price: String?

//    public init(data: [Double],
//                title: String? = nil,
//                price: String? = nil) {
//
//        self.data = data
//        self.title = title
//        self.price = price
//    }
    
    public var body: some View {
        GeometryReader{ geometry in
            VStack(alignment: .leading, spacing: 8) {
                Group{
                    if (self.title != nil){
                        Text(self.title!)
                            .font(.title)
                    }
                    if (self.price != nil){
                        Text(self.price!)
                            .font(.body)
                        .offset(x: 5, y: 0)
                    }
                }.offset(x: 0, y: 0)
                ZStack{
                    GeometryReader{ reader in
                        Line(data: self.data,
                             frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width , height: reader.frame(in: .local).height))
//                             minDataValue: .constant(nil),
//                             maxDataValue: .constant(nil)
                        )
                            .offset(x: 0, y: 0)
                    }
                    .frame(width: geometry.frame(in: .local).size.width, height: 200)
                    .offset(x: 0, y: -100)

                }
                .frame(width: geometry.frame(in: .local).size.width, height: 200)
        
            }
        }
    }
}

struct Line: View {
    @State var data: [(Double)]
    @Binding var frame: CGRect

    let padding:CGFloat = 30
    
    func stepWidth() -> CGFloat {
        if data.count < 2 {
            return 0
        }
        return frame.size.width / CGFloat(data.count-1)
    }
    
    func stepHeight() -> CGFloat {
        var min: Double?
        var max: Double?
        if let minPoint = self.data.min(), let maxPoint = self.data.max(), minPoint != maxPoint {
            min = minPoint
            max = maxPoint
        } else {
            return 0
        }
        if let min = min, let max = max, min != max {
            if (min <= 0){
                return (frame.size.height-padding) / CGFloat(max - min)
            }else{
                return (frame.size.height-padding) / CGFloat(max + min)
            }
        }
        
        return 0
    }
    
    func path() -> Path {
        return lineChart(step: CGPoint(x: stepWidth(), y: stepHeight()))
    }
    
    func lineChart(step:CGPoint) -> Path {
        var path = Path()
        if (self.data.count < 2){
            return path
        }
        guard let offset = self.data.min() else {
            return path
        }
        let p1 = CGPoint(x: 0, y: CGFloat(self.data[0]-offset)*step.y)
        path.move(to: p1)
        for pointIndex in 1..<self.data.count {
            let p2 = CGPoint(x: step.x * CGFloat(pointIndex), y: step.y*CGFloat(self.data[pointIndex]-offset))
            path.addLine(to: p2)
        }
        return path
    }
    
    public var body: some View {
        
        ZStack {

            self.path()
                .stroke(Color.green ,style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                .rotationEffect(.degrees(180), anchor: .center)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .drawingGroup()
        }
    }
}
