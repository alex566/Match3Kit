import XCTest
@testable import Match3Kit

enum Toys: String, GridFilling, CaseIterable {
    case car, pyramide

    var pattern: Match3Kit.Pattern {
        Match3Kit.Pattern(indices: [])
    }
}
