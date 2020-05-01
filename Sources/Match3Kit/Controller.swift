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

public struct Pattern: Equatable, Hashable {
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
        let detected = detect(indices: self.indices, containedIn: indices)
        if !detected.isEmpty {
            return detected
        }
        let detectedRotated = detect(indices: rotated().indices, containedIn: indices)
        if !detectedRotated.isEmpty {
            return detectedRotated
        }
        return []
    }

    public func detectExactIn(indices: Set<Index>) -> Set<Index> {
        detect(indices: self.indices, containedIn: indices)
    }

    private func detect(indices: Set<Index>, containedIn: Set<Index>) -> Set<Index> {
        guard !containedIn.isEmpty else {
            return Set()
        }
        let columns = Set(containedIn.map { $0.column })
        let rows = Set(containedIn.map { $0.row })

        for i in columns {
            for j in rows {
                let figureIndices = Set(indices.map { Index(column: $0.column + i,
                                                            row: $0.row + j) })
                if figureIndices.isSubset(of: containedIn) {
                    return figureIndices
                }
            }
        }
        return Set()
    }
}

/// Grid modifier
public final class Controller<Filling: GridFilling> {

    public let basic: [Filling]
    public let bonuse: [Filling]

    private(set) public var grid: Grid<Filling>

    private let generator: Generator<Filling>
    private let matcher: Matcher<Filling>

    public init<GeneratorType: Generator<Filling>, MatcherType: Matcher<Filling>>(size: Size,
                basic: [Filling],
                bonuse: [Filling],
                generatorType: GeneratorType.Type,
                matcherType: MatcherType.Type) {
        precondition(size.columns >= 3)
        precondition(size.rows >= 3)

        self.basic = basic
        self.bonuse = bonuse

        self.generator = GeneratorType(fillings: basic)
        self.matcher = MatcherType(fillings: basic, minSeries: 3)
        self.grid = generator.generate(of: size)
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

    public func spawn(filling: Filling, at index: Index) -> Grid<Filling>.Cell {
        let cell = generator.generate(at: index, filling: filling)
        grid.setCell(cell, at: index)
        return cell
    }

    public func removeAndRefill(indices: Set<Index>) {
        let removedIndices = grid.remove(cells: indices)
        grid = generator.fill(grid: grid, indices: removedIndices)
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
        index.isNeighboring(with: target)
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

    public func swapAndMatchCell( at index: Index, with target: Index) -> Set<Index> {
        grid.swapCell(at: index, with: target)
        return matcher.findMatches(on: grid, at: index)
            .union(matcher.findMatches(on: grid, at: target))
    }

    public func match(indices: Set<Index>, swapIndices: Set<Index>) -> MatchResult<Filling> {
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
        removeAndRefill(indices: removeIndices)

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
