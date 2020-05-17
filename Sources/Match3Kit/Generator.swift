//
//  Generator.swift
//  Match3Kit
//
//  Created by Alexey on 15.02.2020.
//  Copyright © 2020 Alexey. All rights reserved.
//

open class Generator<Filling: GridFilling> {

    public final let fillings: Set<Filling>
    
    private var nextIndex = 0

    public required init(fillings: Set<Filling>) {
        precondition(fillings.count > 1)
        self.fillings = fillings
    }

    open func generate(of size: Size) -> Grid<Filling> {
        let columns = (0..<size.columns).map { column in
            (0..<size.rows).map { row -> Grid<Filling>.Cell in
                let index = Index(column: column, row: row)
                return generate(at: index)
            }
        }
        return Grid(size: size, columns: columns)
    }

    open func generate(at index: Index, filling: Filling? = nil) -> Grid<Filling>.Cell {
        let filling = filling ?? fillings.randomElement()!
        let cell = Grid<Filling>.Cell(id: nextIndex, filling: filling)
        nextIndex += 1
        return cell
    }

    open func fill(grid: Grid<Filling>, indices: Set<Index>) -> Grid<Filling> {
        var filledGrid = grid
        for index in indices {
            filledGrid.setCell(generate(at: index), at: index)
        }
        return filledGrid
    }
}
