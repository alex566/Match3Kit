//
//  Controller.swift
//  Match3Kit
//
//  Created by Alexey on 15.02.2020.
//  Copyright © 2020 Alexey. All rights reserved.
//

public struct MatchResult<Filling: GridFilling> {
    public let removed: Set<Index>
    public let spawned: [Index: Grid<Filling>.Cell]
}

public struct Pattern: Hashable {
    public let indices: Set<Index>

    public init(indices: Set<Index>) {
        self.indices = indices
    }

    @inlinable
    public func rotated() -> Pattern {
        let rotatedIndices = indices.map { Index(column: $0.row, row: $0.column) }
        return Pattern(indices: Set(rotatedIndices))
    }

    public func detectIn(indices: Set<Index>) -> Set<Index> {
        let detected = Self.detect(indices: self.indices, containedIn: indices)
        if !detected.isEmpty {
            return detected
        }
        let detectedRotated = Self.detect(indices: rotated().indices, containedIn: indices)
        if !detectedRotated.isEmpty {
            return detectedRotated
        }
        return []
    }

    public func detectExactIn(indices: Set<Index>) -> Set<Index> {
        Self.detect(indices: self.indices, containedIn: indices)
    }

    private static func detect(indices: Set<Index>, containedIn: Set<Index>) -> Set<Index> {
        guard !containedIn.isEmpty else {
            return Set()
        }
        let columns = Set(containedIn.map { $0.column })
        let rows = Set(containedIn.map { $0.row })

        for i in columns {
            for j in rows {
                let figureIndices = indices.lazy.map { Index(column: $0.column + i,
                                                             row: $0.row + j) }
                if containedIn.isSuperset(of: figureIndices) {
                    return Set(figureIndices)
                }
            }
        }
        return Set()
    }
}

/// Grid modifier
public final class Controller<Filling: GridFilling, GeneratorType: Generator<Filling>, MatcherType: Matcher<Filling>> {

    public private(set) var basic: Set<Filling>
    public let bonuse: Set<Filling>
    public let obstacles: Set<Filling>

    public enum Refill {
        case spill, regenerate
    }

    private(set) public var grid: Grid<Filling>

    public let generator: GeneratorType
    public let matcher: MatcherType

    public init(size: Size,
                basic: Set<Filling>,
                bonuse: Set<Filling>,
                obstacles: Set<Filling>) {
        precondition(size.columns >= 3)
        precondition(size.rows >= 3)

        self.basic = basic
        self.bonuse = bonuse
        self.obstacles = obstacles

        self.generator = GeneratorType(fillings: basic)
        self.matcher = MatcherType(fillings: basic, minSeries: 3)
        self.grid = generator.generate(of: size)
    }

    public init(grid: Grid<Filling>,
                basic: Set<Filling>,
                bonuse: Set<Filling>,
                obstacles: Set<Filling>) {
        precondition(grid.size.columns >= 3)
        precondition(grid.size.rows >= 3)

        self.basic = basic
        self.bonuse = bonuse
        self.obstacles = obstacles

        self.generator = GeneratorType(fillings: basic)
        self.matcher = MatcherType(fillings: basic, minSeries: 3)
        self.grid = grid
    }

    @inlinable
    public func isBonuse(at index: Index) -> Bool {
        let cell = grid.cell(at: index)
        return bonuse.contains(cell.filling)
    }

    @inlinable
    public func isBasic(at index: Index) -> Bool {
        let cell = grid.cell(at: index)
        return basic.contains(cell.filling)
    }

    @inlinable
    public func isObstacle(at index: Index) -> Bool {
        let cell = grid.cell(at: index)
        return obstacles.contains(cell.filling)
    }

    public func spawn(filling: Filling, at index: Index) -> Grid<Filling>.Cell {
        let cell = generator.generate(at: index, filling: filling)
        grid.setCell(cell, at: index)
        return cell
    }

    public func remove(indices: Set<Index>, refill: Refill) {
        let removedIndices = refill == .spill ? grid.remove(cells: indices) : indices
        grid = generator.fill(grid: grid, indices: removedIndices)
    }

    public func addBasic(_ fillings: Set<Filling>) {
        basic.formUnion(fillings)
        generator.addFillings(fillings)
        matcher.addFillings(fillings)
    }
    public func removeBasic(_ fillings: Set<Filling>) {
        basic.subtract(fillings)
        generator.removeFillings(fillings)
        matcher.removeFillings(fillings)
    }

    // MARK: - Swap
    @inlinable
    public func shouldSwapCell(at index: Index, with target: Index) -> Bool {
        guard index.isNeighboring(with: target) else { return false }
        guard hasMatchesExcanging(index, and: target) else { return false }
        return true
    }

    @inlinable
    public func canSwapCell(at index: Index, with target: Index) -> Bool {
        let cell = grid.cell(at: index)
        let targetCell = grid.cell(at: target)
        return index.isNeighboring(with: target) &&
            !obstacles.contains(cell.filling) && !obstacles.contains(targetCell.filling)
    }

    public func swapCell(at index: Index, with target: Index) {
        grid.swapCell(at: index, with: target)
    }

    public func hasMatchesExcanging(_ index: Index,
                                    and target: Index) -> Bool {
        var updatedGrid = grid
        updatedGrid.swapCell(at: index, with: target)
        return !matcher.findMatches(on: updatedGrid, at: index).isEmpty ||
            !matcher.findMatches(on: updatedGrid, at: target).isEmpty
    }

    public func findAllMatches() -> Set<Index> {
        matcher.findAllMatches(on: grid)
    }

    public func findMatches(indices: Set<Index>) -> Set<Index> {
        matcher.findMatched(on: grid, indices: indices)
    }

    public func swapAndMatchCell(at index: Index, with target: Index) -> Set<Index> {
        grid.swapCell(at: index, with: target)
        return matcher.findMatches(on: grid, at: index)
            .union(matcher.findMatches(on: grid, at: target))
    }

    public func match(indices: Set<Index>, swapIndices: Set<Index>, refill: Refill) -> MatchResult<Filling> {
        var spawnCells = [Index: Grid<Filling>.Cell]()
        var removeIndices = indices
        for bonuse in bonuse {
            let detectedIndices = bonuse.pattern.detectIn(indices: indices)
            if !detectedIndices.isEmpty {
                let intersection = detectedIndices.intersection(swapIndices).first
                let spawnIndex = intersection ?? detectedIndices.randomElement()!
                let spawnedBonuse = generator.generate(at: spawnIndex, filling: bonuse)
                grid.setCell(spawnedBonuse, at: spawnIndex)
                spawnCells[spawnIndex] = spawnedBonuse
                removeIndices.remove(spawnIndex)
            }
        }
        remove(indices: removeIndices, refill: refill)

        return MatchResult(removed: removeIndices,
                           spawned: spawnCells)
    }

    public func findPossibleSwap() -> (Index, Index)? {
        for index in grid.allIndices() {
            for neighbour in index.neighbors
                where grid.size.isOnBounds(neighbour) && hasMatchesExcanging(index, and: neighbour) {
                    return (index, neighbour)
            }
        }
        return nil
    }
}
