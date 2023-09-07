//
//  Matcher.swift
//  Match3Kit
//
//  Created by Alexey on 15.02.2020.
//  Copyright © 2020 Alexey. All rights reserved.
//

/// `Matcher` is a generic class used to identify matching elements in a `Grid`.
/// It requires a set of `GridFilling` elements to match against and a minimum series length for a match to be considered.
///
/// Example usage:
///
/// ```swift
/// let fillings: Set<String> = ["X", "Y", "Z"]
/// let matcher = Matcher(fillings: fillings, minSeries: 3)
/// let matches = matcher.findAllMatches(on: myGrid)
/// ```
///
/// It can also find matches for a subset of indices or at a specific index.
///
/// ```swift
/// let indices: [Index] = [Index(column: 0, row: 0), Index(column: 1, row: 0)]
/// let subsetMatches = matcher.findMatched(on: myGrid, indices: indices)
///
/// let index = Index(column: 0, row: 0)
/// let singleMatch = matcher.findMatches(on: myGrid, at: index)
/// ```
///
/// `Matcher` can be subclassed to change the matching logic. For example, you could create a subclass that matches based on some property of the `GridFilling` other than equality.
///
/// ```swift
/// class CustomMatcher: Matcher<String> {
///     override func match(cell: Grid<String>.Cell, with cellToMatch: Grid<String>.Cell) -> Bool {
///         // Custom matching logic
///     }
/// }
/// ```
///
/// - Note: `Matcher` does not modify the `Grid` or the `GridFilling`. It only identifies matches. The responsibility for handling matches (e.g., removing them from the grid, updating the score) lies elsewhere.
open class Matcher<Filling: GridFilling> {

    public private(set) var fillings: Set<Filling>
    public let minSeries: Int

    internal final func addFillings(_ fillings: Set<Filling>) {
        self.fillings.formUnion(fillings)
    }

    internal final func removeFillings(_ fillings: Set<Filling>) {
        self.fillings.subtract(fillings)
    }

    public required init(fillings: Set<Filling>, minSeries: Int) {
        self.minSeries = minSeries
        self.fillings = fillings
    }

    public func findAllMatches(on grid: Grid<Filling>) -> Set<Index> {
        findMatched(on: grid, indices: grid.allIndices())
    }

    public func findMatched(
        on grid: Grid<Filling>,
        indices: some Collection<Index>
    ) -> Set<Index> {
        Set(indices.flatMap { findMatches(on: grid, at: $0) })
    }

    public func findMatches(on grid: Grid<Filling>, at index: Index) -> Set<Index> {
        let cell = grid[index]
        guard fillings.contains(cell.filling) else {
            return Set()
        }

        let verticalIndicies = matchCellsInRow(on: grid, cell: cell, sequence: index.upperSequence()) +
            matchCellsInRow(on: grid, cell: cell, sequence: index.lowerSequence())
        let horizontalIndicies = matchCellsInRow(on: grid, cell: cell, sequence: index.rightSequence()) +
            matchCellsInRow(on: grid, cell: cell, sequence: index.leftSequence())

        var result = Set<Index>()
        if verticalIndicies.count + 1 >= minSeries {
            result.formUnion(verticalIndicies)
        }
        if horizontalIndicies.count + 1 >= minSeries {
            result.formUnion(horizontalIndicies)
        }
        if !result.isEmpty {
            result.insert(index)
        }
        return result
    }

    open func match(cell: Grid<Filling>.Cell, with cellToMatch: Grid<Filling>.Cell) -> Bool {
        cell.filling == cellToMatch.filling
    }
    
    private func matchCellsInRow(
        on grid: Grid<Filling>,
        cell: Grid<Filling>.Cell,
        sequence: some Sequence<Index>
    ) -> [Index] {
        sequence.prefix {
            grid.size.isOnBounds($0) && match(cell: grid.cell(at: $0), with: cell)
        }
    }
}
