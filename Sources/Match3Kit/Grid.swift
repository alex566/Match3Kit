//
//  Grid.swift
//  Match3Kit
//
//  Created by Alexey on 4/1/19.
//  Copyright © 2019 Alexey. All rights reserved.
//

import Foundation

public struct Size: Hashable, Codable {
    public let columns: Int
    public let rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }

    @inlinable
    public func isOnBounds(_ index: Index) -> Bool {
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

public struct Index: Hashable, Codable, CustomStringConvertible {
    public let column: Int
    public let row: Int

    public init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }

    @inlinable
    public var zero: Index {
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

    @inlinable
    public var neighbors: [Index] {
        [left, upper, right, lower]
    }

    @inlinable
    public var crossNeighbors: [Index] {
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
    public func upperSequence() -> UnfoldFirstSequence<Index> {
        sequence(first: upper) { $0.upper }
    }

    @inlinable
    public func lowerSequence() -> UnfoldFirstSequence<Index> {
        sequence(first: lower) { $0.lower }
    }

    @inlinable
    public func rightSequence() -> UnfoldFirstSequence<Index> {
        sequence(first: right) { $0.right }
    }

    @inlinable
    public func leftSequence() -> UnfoldFirstSequence<Index> {
        sequence(first: left) { $0.left }
    }

    // MARK: - CustomStringConvertible
    public var description: String {
        "(\(column), \(row))"
    }
}

public protocol GridFilling: Hashable, Codable {
    var pattern: Pattern { get }
}

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
        allIndices().filter { cell(at: $0).filling == filling }
    }

    @inlinable
    public func cell(at index: Index) -> Cell {
        columns[index.column][index.row]
    }

    // MARK: - Modification

    public mutating func setCell(_ cell: Cell, at index: Index) {
        columns[index.column][index.row] = cell
    }

    public mutating func remove(cells indicies: Set<Index>) -> Set<Index> {
        let cells = indicies.map(cell(at:))
        var removedIndices = Set<Index>()
        removedIndices.reserveCapacity(indicies.count)
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
