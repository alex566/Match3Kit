//
//  GridModel.swift
//  SwiftUI-Match3Kit
//
//  Created by Alexey on 05.05.2020.
//  Copyright © 2020 Alexey. All rights reserved.
//

import SwiftUI
import Match3Kit

enum Shape: String, CaseIterable, GridFilling {
    case square
    case circle
    case triangle

    var pattern: Pattern {
        Pattern(indices: [])
    }
}

final class GridModel: ObservableObject {

    typealias GridController = Controller<Shape, Generator<Shape>, Matcher<Shape>>

    private let controller = GridController(size: Size(columns: 6, rows: 6),
                                            basic: [.square, .circle, .triangle],
                                            bonuse: [],
                                            obstacles: [])

    var grid: Grid<Shape> {
        controller.grid
    }

    func canSwapCell(at index: Index, with target: Index) -> Bool {
        controller.canSwapCell(at: index, with: target)
    }

    func shouldSwapCell(at index: Index, with target: Index) -> Bool {
        controller.shouldSwapCell(at: index, with: target)
    }

    func swapAndMatchCell( at index: Index, with target: Index) -> Set<Index> {
        controller.swapAndMatchCell(at: index, with: target)
    }

    func remove(indices: Set<Index>, swapIndices: Set<Index> = []) {
        objectWillChange.send()
        
        _ = controller.match(indices: indices, swapIndices: swapIndices, refill: .spill)

        let matches = controller.findAllMatches()
        if !matches.isEmpty {
            self.remove(indices: matches)
        }
    }
}
