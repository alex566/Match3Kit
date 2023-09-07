//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 27.06.23.
//

import XCTest

@testable import Match3Kit

final class MatcherTests: XCTestCase {
    enum Filling: GridFilling {
        case empty
        case x
        case y
        
        var pattern: Match3Kit.Pattern {
            .init(indices: [])
        }
    }

    func testFindMatches() {
        let matcher = Matcher(fillings: [Filling.x], minSeries: 3)
        
        // Initialize grid with empty cells
        var columns = [[Grid<Filling>.Cell]]()
        for _ in 0..<5 {
            var column = [Grid<Filling>.Cell]()
            for _ in 0..<5 {
                let cell = Grid<Filling>.Cell(id: UUID(), filling: .empty)
                column.append(cell)
            }
            columns.append(column)
        }
        
        var grid = Grid<Filling>(size: Size(columns: 5, rows: 5),
                                 columns: columns)
        grid[.init(column: 0, row: 0)] = .init(id: UUID(), filling: .x)
        grid[.init(column: 0, row: 1)] = .init(id: UUID(), filling: .x)
        grid[.init(column: 0, row: 2)] = .init(id: UUID(), filling: .x)
        let matches = matcher.findMatches(on: grid, at: Index(column: 0, row: 0))
        XCTAssertEqual(matches.count, 3, "Should find 3 matches")
    }

    func testMatchCell() {
        let matcher = Matcher(fillings: [Filling.x], minSeries: 3)
        let cell1 = Grid<Filling>.Cell(id: UUID(), filling: .x)
        let cell2 = Grid<Filling>.Cell(id: UUID(), filling: .x)
        let isMatch = matcher.match(cell: cell1, with: cell2)
        XCTAssertTrue(isMatch, "Should match cells with the same filling")
    }

    func testMatchCellFails() {
        let matcher = Matcher(fillings: [Filling.x, .y], minSeries: 3)
        let cell1 = Grid<Filling>.Cell(id: UUID(), filling: .x)
        let cell2 = Grid<Filling>.Cell(id: UUID(), filling: .y)
        let isMatch = matcher.match(cell: cell1, with: cell2)
        XCTAssertFalse(isMatch, "Should not match cells with different fillings")
    }
}
