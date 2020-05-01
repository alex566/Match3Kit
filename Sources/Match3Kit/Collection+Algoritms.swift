//
//  Collection+Algoritms.swift
//  Match3Kit
//
//  Created by Alexey on 4/5/19.
//  Copyright © 2019 Alexey. All rights reserved.
//

public extension MutableCollection {

    /// Swaps the elements of the two given subranges, up to the upper bound of
    /// the smaller subrange. The returned indices are the ends of the two ranges
    /// that were actually swapped.
    ///
    ///     Input:
    ///     [a b c d e f g h i j k l m n o p]
    ///      ^^^^^^^         ^^^^^^^^^^^^^
    ///      lhs             rhs
    ///
    ///     Output:
    ///     [i j k l e f g h a b c d m n o p]
    ///             ^               ^
    ///             p               q
    ///
    /// - Precondition: !lhs.isEmpty && !rhs.isEmpty
    /// - Postcondition: For returned indices `(p, q)`:
    ///   - distance(from: lhs.lowerBound, to: p) ==
    ///       distance(from: rhs.lowerBound, to: q)
    ///   - p == lhs.upperBound || q == rhs.upperBound
    @inline(__always)
    private mutating func _swapNonemptySubrangePrefixes(
        _ lhs: Range<Index>, _ rhs: Range<Index>
        ) -> (Index, Index) {
        assert(!lhs.isEmpty)
        assert(!rhs.isEmpty)

        var p = lhs.lowerBound
        var q = rhs.lowerBound
        repeat {
            swapAt(p, q)
            formIndex(after: &p)
            formIndex(after: &q)
        }
            while p != lhs.upperBound && q != rhs.upperBound
        return (p, q)
    }

    /// Rotates the elements of the collection so that the element
    /// at `middle` ends up first.
    ///
    /// - Returns: The new index of the element that was first
    ///   pre-rotation.
    /// - Complexity: O(*n*)
    mutating func rotate(shiftingToStart middle: Index) -> Index {
        var m = middle, s = startIndex
        let e = endIndex

        // Handle the trivial cases
        if s == m { return e }
        if m == e { return s }

        // We have two regions of possibly-unequal length that need to be
        // exchanged.  The return value of this method is going to be the
        // position following that of the element that is currently last
        // (element j).
        //
        //   [a b c d e f g|h i j]   or   [a b c|d e f g h i j]
        //   ^             ^     ^        ^     ^             ^
        //   s             m     e        s     m             e
        //
        var ret = e // start with a known incorrect result.
        while true {
            // Exchange the leading elements of each region (up to the
            // length of the shorter region).
            //
            //   [a b c d e f g|h i j]   or   [a b c|d e f g h i j]
            //    ^^^^^         ^^^^^          ^^^^^ ^^^^^
            //   [h i j d e f g|a b c]   or   [d e f|a b c g h i j]
            //   ^     ^       ^     ^         ^    ^     ^       ^
            //   s    s1       m    m1/e       s   s1/m   m1      e
            //
            let (s1, m1) = _swapNonemptySubrangePrefixes(s..<m, m..<e)

            if m1 == e {
                // Left-hand case: we have moved element j into position.  if
                // we haven't already, we can capture the return value which
                // is in s1.
                //
                // Note: the STL breaks the loop into two just to avoid this
                // comparison once the return value is known.  I'm not sure
                // it's a worthwhile optimization, though.
                if ret == e { ret = s1 }

                // If both regions were the same size, we're done.
                if s1 == m { break }
            }

            // Now we have a smaller problem that is also a rotation, so we
            // can adjust our bounds and repeat.
            //
            //    h i j[d e f g|a b c]   or    d e f[a b c|g h i j]
            //         ^       ^     ^              ^     ^       ^
            //         s       m     e              s     m       e
            s = s1
            if s == m { m = m1 }
        }

        return ret
    }

    /// Moves all elements satisfying `isSuffixElement` into a suffix of the
    /// collection, preserving their relative order, and returns the start of the
    /// resulting suffix.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    mutating func stablePartition(
        isSuffixElement: (Element) throws -> Bool
        ) rethrows -> Index {
        return try stablePartition(count: count, isSuffixElement: isSuffixElement)
    }

    /// Moves all elements satisfying `isSuffixElement` into a suffix of the
    /// collection, preserving their relative order, and returns the start of the
    /// resulting suffix.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    /// - Precondition: `n == self.count`
    mutating func stablePartition(
        count n: Int, isSuffixElement: (Element) throws-> Bool
        ) rethrows -> Index {
        if n == 0 { return startIndex }
        if n == 1 {
            return try isSuffixElement(self[startIndex]) ? startIndex : endIndex
        }
        let h = n / 2, i = index(startIndex, offsetBy: h)
        let j = try self[..<i].stablePartition(
            count: h, isSuffixElement: isSuffixElement)
        let k = try self[i...].stablePartition(
            count: n - h, isSuffixElement: isSuffixElement)
        return self[j..<k].rotate(shiftingToStart: i)
    }
}
