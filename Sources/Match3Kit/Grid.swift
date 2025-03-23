//
//  Grid.swift
//  Match3Kit
//
//  Created by Alexey on 4/1/19.
//  Copyright © 2019 Alexey. All rights reserved.
//

import Foundation

/// `Size` represents the size of a two-dimensional grid in terms of columns and rows.
///
/// It provides useful properties and methods related to grid dimensions, including:
/// - A method `isOnBounds(_:)` that checks if a given `Index` falls within the grid bounds.
/// - Computed properties `lowerBound`, `upperBound`, `leftBound`, and `rightBound` which define the grid boundaries.
///
/// This struct conforms to `Hashable` and `Codable`, enabling instances to be compared, hashed, encoded, and decoded.
///
/// Example usage:
/// ```
/// var gridSize = Size(columns: 5, rows: 5)
/// var index = Index(column: 2, row: 2)
/// print(gridSize.isOnBounds(index)) // Prints: "true"
/// ```
///
/// - Note: This struct considers `-1` as lower and left bounds, which implies it supports negative indexing.
///         Make sure this aligns with your grid indexing requirements.
public struct Size: Hashable, Codable {
    public let columns: Int
    public let rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }

    /// Checks if an index is within the bounds of the grid.
    ///
    /// - Parameter index: The index to check.
    /// - Returns: `true` if the index is within the bounds of the grid, `false` otherwise.
    @inlinable
    public func isInBounds(_ index: Index) -> Bool {
        index.column > leftBound && index.column < rightBound &&
            index.row > lowerBound && index.row < upperBound
    }

    @inlinable
    public var lowerBound: Int { -1 }

    @inlinable
    public var upperBound: Int { rows }

    @inlinable
    public var leftBound: Int { -1 }

    @inlinable
    public var rightBound: Int { columns }
}

/// `Index` represents a location in a two-dimensional grid using `column` and `row` properties.
///
/// It provides methods and properties that facilitate grid navigation:
/// - Computed properties for neighboring locations: `upper`, `lower`, `right`, `left`.
/// - Computed properties for sequences of neighboring locations: `upperSequence`, `lowerSequence`, `rightSequence`, `leftSequence`.
/// - A method `isNeighboring(with:)` that checks if a given index is neighboring the current index.
/// - A static property `zero` which represents the origin (0,0) index.
///
/// Additionally, it provides arrays of immediate `neighbors` and diagonal `crossNeighbors`.
///
/// The struct also conforms to `Hashable`, `Codable`, and `CustomStringConvertible`.
/// This allows for instances to be compared, hashed, encoded, decoded, and converted to a readable string format.
///
/// Example usage:
/// ```
/// var index = Index(column: 2, row: 2)
/// print(index.upper) // Prints: "(2, 3)"
/// ```
public struct Index: Hashable, Codable, CustomStringConvertible {
    public let column: Int
    public let row: Int

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }

    @inlinable
    public static var zero: Index {
        Index(column: 0, row: 0)
    }

    // MARK: - Neighbors
    @inlinable
    public var upper: Index {
        Index(column: column, row: row + 1)
    }

    @inlinable
    public var lower: Index {
        Index(column: column, row: row - 1)
    }

    @inlinable
    public var right: Index {
        Index(column: column + 1, row: row)
    }

    @inlinable
    public var left: Index {
        Index(column: column - 1, row: row)
    }

    /// Returns an array of immediate neighbors of the current index.
    ///
    /// The neighbors are the indices immediately adjacent to the current index,
    /// including the upper, lower, right, and left neighbors.
    ///
    /// Example usage:
    /// ```
    /// let index = Index(column: 2, row: 2)
    /// let neighbors = index.neighbors
    /// print(neighbors) // Prints: "[Index(column: 1, row: 2), Index(column: 3, row: 2), Index(column: 2, row: 1), Index(column: 2, row: 3)]"
    /// ```
    @inlinable
    public var neighbors: [Index] {
        [left, upper, right, lower]
    }

    /// Returns an array of diagonal neighbors of the current index.
    ///
    /// The diagonal neighbors are the indices diagonally adjacent to the current index,
    /// including the upper-left, upper-right, lower-left, and lower-right neighbors.
    ///
    /// Example usage:
    /// ```
    /// let index = Index(column: 2, row: 2)
    /// let diagonalNeighbors = index.diagonalNeighbors
    /// print(diagonalNeighbors) // Prints: "[Index(column: 1, row: 1), Index(column: 3, row: 3), Index(column: 1, row: 3), Index(column: 3, row: 1)]"
    /// ```
    @inlinable
    public var diagonalNeighbors: [Index] {
        [Index(column: column - 1, row: row - 1),
         Index(column: column + 1, row: row + 1),
         Index(column: column - 1, row: row + 1),
         Index(column: column + 1, row: row - 1)]
    }

    @inlinable
    public func isNeighboring(with index: Index) -> Bool {
        neighbors.contains(index)
    }

    // MARK: - Sequences
    @inlinable
    public func upperSequence() -> some Sequence<Index> {
        sequence(first: upper) { $0.upper }
    }

    @inlinable
    public func lowerSequence() -> some Sequence<Index> {
        sequence(first: lower) { $0.lower }
    }

    @inlinable
    public func rightSequence() -> some Sequence<Index> {
        sequence(first: right) { $0.right }
    }

    @inlinable
    public func leftSequence() -> some Sequence<Index> {
        sequence(first: left) { $0.left }
    }

    // MARK: - CustomStringConvertible
    public var description: String {
        "(\(column), \(row))"
    }
}

/// `GridFilling` defines a protocol for items that can fill the cells of a `Grid`.
///
/// Conforming types must provide a `pattern` property, which could represent the visual pattern,
/// value pattern or any other attributes that describe how this object fills a grid cell.
///
/// Example usage:
/// ```
/// struct MyFilling: PatternedGridFilling {
///     var pattern: Pattern {
///         // Define the pattern here
///     }
/// }
///
/// var myFilling = MyFilling()
/// var grid = Grid<MyFilling>(size: Size(columns: 5, rows: 5), fill: myFilling)
/// ```
public protocol GridFilling: Hashable, Codable {
    var pattern: Pattern { get }
}

/// `Grid` represents the game field in a match-3 game, populated with items that conform to `GridFilling`.
///
/// Each cell in the `Grid` can hold a single `Cell` instance. A `Cell` holds an instance of `GridFilling`, which can represent a gem, bomb, or other game piece.
///
/// The `Grid` also provides methods for manipulating its contents, such as:
/// - `setCell(_:at:)` for replacing the content of a cell.
/// - `remove(cells:)` for removing multiple cells from the grid.
/// - `swapCell(at:with:)` for swapping the contents of two cells.
/// - `cell(at:)` for retrieving the content of a specific cell.
///
/// Other useful properties and methods include:
/// - `size` for getting the size of the grid.
/// - `allIndices()` and `allIndices(of:)` for retrieving all indices, or all indices containing a specific filling.
///
/// Example usage:
/// ```
/// typealias GridController = Controller<Shape, Generator<Shape>, Matcher<Shape>>
/// private let controller = GridController(
///     size: Size(columns: 6, rows: 6),
///     basic: [.square, .circle, .triangle],
///     bonuse: [],
///     obstacles: []
/// )
///  controller.grid.setCell(.init(id: UUID(), filling: .square), at: .init(column: 0, row: 0))
/// ```
///
/// The `Grid` structure is `Codable` which means it can be serialized and deserialized, allowing for the saving/loading of game states.
public struct Grid<Filling>: Codable where Filling: GridFilling {

    public let size: Size
    public private(set) var columns: [[Cell]]

    public struct Cell: Hashable, Codable, Identifiable {
        public var id: UUID
        public let filling: Filling

        public init(id: UUID,
                    filling: Filling) {
            self.id = id
            self.filling = filling
        }
    }

    internal init(size: Size, columns: [[Cell]]) {
        self.size = size
        self.columns = columns
    }

    public func allIndices() -> [Index] {
        var result = [Index]()
        result.reserveCapacity(size.columns * size.rows)
        for column in columns.indices {
            for row in columns[column].indices {
                result.append(Index(column: column, row: row))
            }
        }
        return result
    }

    @inlinable
    public func allIndices(of filling: Filling) -> [Index] {
        allIndices().filter { self[$0].filling == filling }
    }

    @inlinable
    public func cell(at index: Index) -> Cell {
        columns[index.column][index.row]
    }

    // MARK: - Modification

    public subscript(index: Index) -> Cell {
        get {
            columns[index.column][index.row]
        }
        set {
            columns[index.column][index.row] = newValue
        }
    }
    
    public mutating func setCell(_ cell: Cell, at index: Index) {
        columns[index.column][index.row] = cell
    }

    public mutating func remove(cells indices: Set<Index>) -> Set<Index> {
        let cells = indices.map(cell(at:))
        var removedIndices = Set<Index>()
        removedIndices.reserveCapacity(indices.count)
        for i in columns.indices {
            let start = columns[i].stablePartition { cells.contains($0) }
            let columnIndices = columns[i][start...].indices.map { Index(column: i, row: $0) }
            removedIndices.formUnion(columnIndices)
        }
        return removedIndices
    }

    public mutating func swapCell(at index: Index, with target: Index) {
        let tmp = cell(at: index)
        columns[index.column][index.row] = cell(at: target)
        columns[target.column][target.row] = tmp
    }
}

// MARK: - CustomStringConvertible
extension Grid: CustomStringConvertible {

    public var description: String {
        (0..<size.upperBound).reduce("") { result, row in
            return result + columns.reduce("") {
                $0 + "\($1[size.upperBound - row - 1].filling)\t" } + "\n"
        }
    }
}
