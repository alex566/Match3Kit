//
//  GridView.swift
//  SwiftUI-Match3Kit
//
//  Created by Alexey on 05.05.2020.
//  Copyright © 2020 Alexey. All rights reserved.
//

import SwiftUI
import Match3Kit

struct GridView: View {

    @ObservedObject var model = GridModel()

    @State var selected: Index?
    
    // Animation states
    @State private var swappingIndices: (Index, Index)?
    @State private var removingCellIDs: Set<UUID> = []
    @State private var newCellIDs: Set<UUID> = []
    @State private var isAnimating = false
    
    private let cellSize: CGFloat = 40
    private let cellSpacing: CGFloat = 4
    private let animationDuration: Double = 0.3

    var body: some View {
        ZStack {
            gridContent
        }
        .padding()
    }
    
    private var gridContent: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(model.grid.columns.indices, id: \.self) { column in
                    ForEach(model.grid.columns[column].indices, id: \.self) { row in
                        cellView(at: Index(column: column, row: row))
                    }
                }
            }
            .frame(width: CGFloat(model.grid.size.columns) * (cellSize + cellSpacing),
                   height: CGFloat(model.grid.size.rows) * (cellSize + cellSpacing))
        }
        .frame(width: CGFloat(model.grid.size.columns) * (cellSize + cellSpacing),
               height: CGFloat(model.grid.size.rows) * (cellSize + cellSpacing))
    }
    
    private func cellView(at index: Index) -> some View {
        let cell = model.grid.cell(at: index)
        let isSelected = index == selected
        let isRemoving = removingCellIDs.contains(cell.id)
        let isNew = newCellIDs.contains(cell.id)
        let position = cellPosition(for: index)
        
        return GridCellView(cell: cell)
            .frame(width: cellSize, height: cellSize)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .opacity(isRemoving ? 0.0 : (isNew ? 0.0 : 1.0))
            .position(position)
            .animation(.easeInOut(duration: animationDuration), value: position)
            .animation(.easeOut(duration: animationDuration), value: isRemoving)
            .animation(.easeIn(duration: animationDuration), value: isNew)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            .gesture(tapGesture(index: index, isSelected: isSelected))
            .allowsHitTesting(!isAnimating)
    }
    
    private func cellPosition(for index: Index) -> CGPoint {
        var targetIndex = index
        
        // Apply swap offset during animation
        if let (first, second) = swappingIndices {
            if index == first {
                targetIndex = second
            } else if index == second {
                targetIndex = first
            }
        }
        
        let x = CGFloat(targetIndex.column) * (cellSize + cellSpacing) + cellSize / 2
        // Invert Y so row 0 is at the bottom
        let y = CGFloat(model.grid.size.rows - 1 - targetIndex.row) * (cellSize + cellSpacing) + cellSize / 2
        
        return CGPoint(x: x, y: y)
    }

    func tapGesture(index: Index, isSelected: Bool) -> some Gesture {
        TapGesture().onEnded { _ in
            guard !isAnimating else { return }
            
            if isSelected {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    self.selected = nil
                }
            } else if self.canSwapSelected(with: index) {
                self.swapWithSelected(index: index)
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    self.selected = index
                }
            }
        }
    }

    func canSwapSelected(with index: Index) -> Bool {
        guard let selected = selected else { return false }
        return self.model.canSwapCell(at: index, with: selected)
    }

    func swapWithSelected(index: Index) {
        guard let selected = selected else { return }
        self.selected = nil
        isAnimating = true

        guard model.shouldSwapCell(at: index, with: selected) else {
            // Invalid swap - animate bounce back
            animateInvalidSwap(index: index, selected: selected)
            return
        }

        // Step 1: Animate the swap visually
        withAnimation(.easeInOut(duration: animationDuration)) {
            swappingIndices = (index, selected)
        }
        
        // Step 2: After swap animation, get matched indices and update model
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            let matchedIndices = model.swapAndMatchCell(at: index, with: selected)
            swappingIndices = nil
            
            // Step 3: Animate removal sequence
            animateRemovalSequence(indices: matchedIndices, swapIndices: [index, selected])
        }
    }
    
    private func animateInvalidSwap(index: Index, selected: Index) {
        // Animate swap
        withAnimation(.easeInOut(duration: animationDuration * 0.5)) {
            swappingIndices = (index, selected)
        }
        
        // Animate back
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration * 0.5) {
            withAnimation(.easeInOut(duration: animationDuration * 0.5)) {
                swappingIndices = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration * 0.5) {
                isAnimating = false
            }
        }
    }
    
    private func animateRemovalSequence(indices: Set<Index>, swapIndices: Set<Index>) {
        guard !indices.isEmpty else {
            isAnimating = false
            return
        }
        
        // Collect cell IDs that will be removed
        let cellIDsToRemove = Set(indices.map { model.grid.cell(at: $0).id })
        
        // Phase 1: Fade out matched cells
        withAnimation(.easeOut(duration: animationDuration)) {
            removingCellIDs = cellIDsToRemove
        }
        
        // Phase 2: After fade out, update model (spill down) and track new cells
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            removingCellIDs = []
            
            // Get current cell IDs before update
            let oldCellIDs = getAllCellIDs()
            
            // Update the model - this will spill cells down and create new ones
            model.remove(indices: indices, swapIndices: swapIndices)
            
            // Find new cell IDs (cells that didn't exist before)
            let currentCellIDs = getAllCellIDs()
            let spawnedCellIDs = currentCellIDs.subtracting(oldCellIDs)
            
            // Mark new cells as hidden initially
            newCellIDs = spawnedCellIDs
            
            // Phase 3: Animate new cells fading in (after spill animation completes)
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                withAnimation(.easeIn(duration: animationDuration)) {
                    newCellIDs = []
                }
                
                // Check for chain reactions after all animations complete
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
                    let chainMatches = model.findAllMatches()
                    if !chainMatches.isEmpty {
                        animateRemovalSequence(indices: chainMatches, swapIndices: [])
                    } else {
                        isAnimating = false
                    }
                }
            }
        }
    }
    
    private func getAllCellIDs() -> Set<UUID> {
        var ids = Set<UUID>()
        for column in model.grid.columns.indices {
            for row in model.grid.columns[column].indices {
                let cell = model.grid.cell(at: Index(column: column, row: row))
                ids.insert(cell.id)
            }
        }
        return ids
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        GridView()
    }
}
