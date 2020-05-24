# Match3Kit

Library for simple Match3 games.
It can work with a solid grid of figures and spill them only in columns.

![Forest walk](./Images/forest-walk.gif)

## Example
Create the enum for all kinds of figures:
```Swift
typealias MyGrid = Grid<Shape>
typealias MyController = Controller<Shape>

enum Shapes: String, GridFilling {
    case square
    case circle
    case triangle

    var pattern: Pattern {
        Pattern(indices: [])
    }
}
``` 

Create a grid controller with configurations:
```Swift
let controller = MyController(
    size: Size(columns: 6, rows: 6),
    basic: [.square, .circle, .triangle],
    bonuse: [],
    generatorType: Generator<Shape>.self,
    matcherType: Matcher<Shape>.self
)
```

Create UI based on the grid that the controller generated:
```Swift
for index in allIndices {
    let cell = controller.grid.cell(at: index)
    setupUI(for: cell, at: index)
}
```

Swap figures after the user interaction: 
```Swift
func swap(source: Index, target: Index) {
    if controller.canSwapCell(at: source, with: target) {
        swapUI(source, target)
        if controller.shouldSwapCell(at: source, with: target) {
            let indices = controller.swapAndMatchCell(at: source, with: target)
            let match = controller.match(indices: indices, swapIndices: [source, target], refill: .spill)
            remove(indices)
            spawn(match.spawned)
            spill(match.removed)
        } else {
            swapUI(source, target)
        }
    } 
}
```

## TODO:
- Add more examples with bonuses
- Add a demo project

## Used in:
# Forest walk
[![Forest walk](./Images/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg)](https://apps.apple.com/app/apple-store/id1513811419?pt=120889283&ct=match3kit&mt=8 "Forest walk")

