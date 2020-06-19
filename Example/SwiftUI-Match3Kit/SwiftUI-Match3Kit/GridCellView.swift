//
//  GridCellView.swift
//  SwiftUI-Match3Kit
//
//  Created by Alexey on 05.05.2020.
//  Copyright © 2020 Alexey. All rights reserved.
//

import SwiftUI
import Match3Kit

struct Triangle: SwiftUI.Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

struct GridCellView: View {
    let cell: Grid<Shape>.Cell

    var body: some View {
        switch cell.filling {
        case .square:
            return AnyView(Rectangle().fill(Color.red).frame(width: 30.0, height: 30.0))
        case .circle:
            return AnyView(Circle().fill(Color.green).frame(width: 30.0, height: 30.0))
        case .triangle:
            return AnyView(Triangle().fill(Color.blue).frame(width: 30.0, height: 30.0))
        }
    }
}

struct GridCellView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(Shape.allCases, id: \.self) { shape in
            GridCellView(cell: Grid<Shape>.Cell(id: UUID(),
                                                filling: shape))
        }
    }
}
