//
//  GridView.swift
//  SwiftUI-Match3Kit
//
//  Created by Alexey on 05.05.2020.
//  Copyright © 2020 Alexey. All rights reserved.
//

import SwiftUI
import Match3Kit

struct GridView: View {

    @ObservedObject var model = GridModel()

    @State var selected: Index?

    var body: some View {
        HStack {
            ForEach(model.grid.columns.indices) { column in
                VStack {
                    ForEach(self.model.grid.columns[column].indices.reversed(), id: \.self) { row in
                        self.buildCell(at: Index(column: column, row: row))
                    }
                }
            }
        }
    }

    func buildCell(at index: Index) -> some View {
        let cell = model.grid.cell(at: index)
        let isSelected = index == selected

        return GridCellView(cell: cell)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.easeOut)
            .gesture(tapGesture(index: index, isSelected: isSelected))
    }

    func tapGesture(index: Index, isSelected: Bool) -> some Gesture {
        TapGesture().onEnded { _ in
            if isSelected {
                self.selected = nil
            } else if self.canSwapSelected(with: index) {
                self.swapWithSelected(index: index)
            } else {
                self.selected = index
            }
        }
    }

    func canSwapSelected(with index: Index) -> Bool {
        guard let selected = selected else { return false }
        return self.model.canSwapCell(at: index, with: selected)
    }

    func swapWithSelected(index: Index) {
        guard let selected = selected else { return }
        self.selected = nil

        guard model.shouldSwapCell(at: index, with: selected) else { return }

        let indices = model.swapAndMatchCell(at: index, with: selected)

        model.remove(indices: indices, swapIndices: [index, selected])
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView()
    }
}
