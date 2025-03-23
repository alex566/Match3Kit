//
//  GridTests.swift
//
//
//  Created by Alexey Oleynik on 27.06.23.
//

import XCTest

@testable import Match3Kit

final class SizeTests: XCTestCase {

    func testInitialization() {
        let size = Size(columns: 5, rows: 10)
        XCTAssertEqual(size.columns, 5)
        XCTAssertEqual(size.rows, 10)
    }

    func testBounds() {
        let size = Size(columns: 5, rows: 10)
        XCTAssertEqual(size.lowerBound, -1)
        XCTAssertEqual(size.upperBound, 10)
        XCTAssertEqual(size.leftBound, -1)
        XCTAssertEqual(size.rightBound, 5)
    }

    func testIsOnBounds() {
        let size = Size(columns: 5, rows: 10)
        // Testing within bounds
        XCTAssertTrue(size.isInBounds(Index(column: 0, row: 0)))
        XCTAssertTrue(size.isInBounds(Index(column: 4, row: 9)))
        // Testing at bounds
        XCTAssertFalse(size.isInBounds(Index(column: -1, row: 0)))
        XCTAssertFalse(size.isInBounds(Index(column: 5, row: 0)))
        XCTAssertFalse(size.isInBounds(Index(column: 0, row: -1)))
        XCTAssertFalse(size.isInBounds(Index(column: 0, row: 10)))
        // Testing out of bounds
        XCTAssertFalse(size.isInBounds(Index(column: -2, row: 0)))
        XCTAssertFalse(size.isInBounds(Index(column: 6, row: 0)))
        XCTAssertFalse(size.isInBounds(Index(column: 0, row: -2)))
        XCTAssertFalse(size.isInBounds(Index(column: 0, row: 11)))
    }
}

final class IndexTests: XCTestCase {

    func testInitialization() {
        let index = Index(column: 5, row: 10)
        XCTAssertEqual(index.column, 5)
        XCTAssertEqual(index.row, 10)
    }

    func testZero() {
        let zeroIndex = Index.zero
        XCTAssertEqual(zeroIndex.column, 0)
        XCTAssertEqual(zeroIndex.row, 0)
    }

    func testNeighbors() {
        let index = Index(column: 5, row: 10)
        XCTAssertEqual(index.upper, Index(column: 5, row: 11))
        XCTAssertEqual(index.lower, Index(column: 5, row: 9))
        XCTAssertEqual(index.right, Index(column: 6, row: 10))
        XCTAssertEqual(index.left, Index(column: 4, row: 10))
    }

    func testCrossNeighbors() {
        let index = Index(column: 5, row: 10)
        XCTAssertEqual(index.diagonalNeighbors, [
            Index(column: 4, row: 9),
            Index(column: 6, row: 11),
            Index(column: 4, row: 11),
            Index(column: 6, row: 9)
        ])
    }

    func testIsNeighboring() {
        let index = Index(column: 5, row: 10)
        let neighboringIndex = Index(column: 6, row: 10)
        let nonNeighboringIndex = Index(column: 7, row: 10)

        XCTAssertTrue(index.isNeighboring(with: neighboringIndex))
        XCTAssertFalse(index.isNeighboring(with: nonNeighboringIndex))
    }

    func testSequences() {
        let index = Index(column: 5, row: 10)
        let expectedUpperSequence = Array(11...20).map { Index(column: 5, row: $0) }
        let expectedLowerSequence = Array(0..<10).reversed().map { Index(column: 5, row: $0) }
        let expectedRightSequence = Array(6...15).map { Index(column: $0, row: 10) }
        let expectedLeftSequence = Array(-5..<5).reversed().map { Index(column: $0, row: 10) }
        
        XCTAssertEqual(Array(index.upperSequence().prefix(10)), expectedUpperSequence)
        XCTAssertEqual(Array(index.lowerSequence().prefix(10)), expectedLowerSequence)
        XCTAssertEqual(Array(index.rightSequence().prefix(10)), expectedRightSequence)
        XCTAssertEqual(Array(index.leftSequence().prefix(10)), expectedLeftSequence)
    }
}

final class GridTests: XCTestCase {

    // Define a simple filling type for the purpose of testing
    struct TestFilling: GridFilling {
        var pattern: Match3Kit.Pattern {
            .init(indices: [])
        }
    }

    func testInitialization() {
        let size = Size(columns: 5, rows: 5)
        let columns: [[Grid<TestFilling>.Cell]] = Array(repeating: Array(repeating: Grid<TestFilling>.Cell(id: UUID(), filling: TestFilling()), count: size.rows), count: size.columns)
        let grid = Grid<TestFilling>(size: size, columns: columns)

        XCTAssertEqual(grid.size, size)
        XCTAssertEqual(grid.columns.count, size.columns)
        grid.columns.forEach { column in
            XCTAssertEqual(column.count, size.rows)
        }
    }

    func testCellAccess() {
        let size = Size(columns: 5, rows: 5)
        let columns: [[Grid<TestFilling>.Cell]] = Array(repeating: Array(repeating: Grid<TestFilling>.Cell(id: UUID(), filling: TestFilling()), count: size.rows), count: size.columns)
        var grid = Grid<TestFilling>(size: size, columns: columns)

        let index = Index(column: 2, row: 2)
        let cell = grid.cell(at: index)

        XCTAssertEqual(cell, grid.columns[index.column][index.row])

        let newCell = Grid<TestFilling>.Cell(id: UUID(), filling: TestFilling())
        grid.setCell(newCell, at: index)

        XCTAssertEqual(newCell, grid.cell(at: index))
    }

    func testAllIndices() {
        let size = Size(columns: 5, rows: 5)
        let columns: [[Grid<TestFilling>.Cell]] = Array(repeating: Array(repeating: Grid<TestFilling>.Cell(id: UUID(), filling: TestFilling()), count: size.rows), count: size.columns)
        let grid = Grid<TestFilling>(size: size, columns: columns)

        let allIndices = grid.allIndices()

        XCTAssertEqual(allIndices.count, size.columns * size.rows)
        for i in 0..<size.columns {
            for j in 0..<size.rows {
                XCTAssertTrue(allIndices.contains(Index(column: i, row: j)))
            }
        }
    }

    func testSwapCells() {
        let size = Size(columns: 5, rows: 5)
        let columns: [[Grid<TestFilling>.Cell]] = Array(repeating: Array(repeating: Grid<TestFilling>.Cell(id: UUID(), filling: TestFilling()), count: size.rows), count: size.columns)
        var grid = Grid<TestFilling>(size: size, columns: columns)

        let index1 = Index(column: 2, row: 2)
        let index2 = Index(column: 3, row: 3)
        let cell1 = grid.cell(at: index1)
        let cell2 = grid.cell(at: index2)

        grid.swapCell(at: index1, with: index2)

        XCTAssertEqual(cell1, grid.cell(at: index2))
        XCTAssertEqual(cell2, grid.cell(at: index1))
    }
}
