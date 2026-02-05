import SwiftUI

struct GridEditorView: View {
    @Binding var rect: NormalizedRect

    private let columns = 24
    private let rows = 16

    @State private var dragStart: GridCell?
    @State private var activeHandle: ResizeHandle?
    @State private var moveStartRect: NormalizedRect?
    @State private var moveStartPoint: CGPoint?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cellSize = CGSize(width: size.width / CGFloat(columns), height: size.height / CGFloat(rows))
            let selection = selectionRange()

            ZStack {
                dotGrid(size: size, cellSize: cellSize, selection: selection)

                let selectionRect = selectionRect(in: size)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .frame(width: selectionRect.size.width, height: selectionRect.size.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("grid"))
                            .onChanged { value in
                                guard activeHandle == nil else { return }
                                if moveStartRect == nil {
                                    moveStartRect = rect
                                    moveStartPoint = value.startLocation
                                }
                                guard let startRect = moveStartRect,
                                      let startPoint = moveStartPoint else { return }
                                let deltaX = (value.location.x - startPoint.x) / cellSize.width
                                let deltaY = (value.location.y - startPoint.y) / cellSize.height
                                let dx = Double(deltaX) / Double(columns)
                                let dy = Double(deltaY) / Double(rows)
                                var newRect = startRect
                                newRect.x = clampDouble(startRect.x + dx, min: 0, max: 1 - startRect.width)
                                newRect.y = clampDouble(startRect.y + dy, min: 0, max: 1 - startRect.height)
                                rect = newRect
                            }
                            .onEnded { _ in
                                moveStartRect = nil
                                moveStartPoint = nil
                            }
                    )

                resizeHandles(in: selectionRect, cellSize: cellSize)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if activeHandle != nil { return }
                        if moveStartRect != nil { return }
                        let startCell = dragStart ?? cell(for: value.startLocation, cellSize: cellSize)
                        dragStart = startCell
                        let current = cell(for: value.location, cellSize: cellSize)
                        rect = normalizedRect(from: startCell, to: current)
                    }
                    .onEnded { _ in
                        dragStart = nil
                    }
            )
        }
        .background(Color.black.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .coordinateSpace(name: "grid")
    }

    private func dotGrid(size: CGSize, cellSize: CGSize, selection: GridRange) -> some View {
        Canvas { context, _ in
            for row in 0..<rows {
                for col in 0..<columns {
                    let center = CGPoint(
                        x: CGFloat(col) * cellSize.width + cellSize.width / 2,
                        y: CGFloat(row) * cellSize.height + cellSize.height / 2
                    )
                    let isSelected = selection.contains(column: col, row: row)
                    let dotSize = min(cellSize.width, cellSize.height) * (isSelected ? 0.8 : 0.35)
                    let rect = CGRect(
                        x: center.x - dotSize / 2,
                        y: center.y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    let path = Path(roundedRect: rect, cornerRadius: dotSize * 0.2)
                    if isSelected {
                        context.fill(path, with: .color(Color.accentColor))
                    } else {
                        context.fill(path, with: .color(.white.opacity(0.2)))
                    }
                }
            }
        }
    }

    private func cell(for location: CGPoint, cellSize: CGSize) -> GridCell {
        let col = min(max(Int(location.x / cellSize.width), 0), columns - 1)
        let row = min(max(Int(location.y / cellSize.height), 0), rows - 1)
        return GridCell(column: col, row: row)
    }

    private func normalizedRect(from start: GridCell, to end: GridCell) -> NormalizedRect {
        let minCol = min(start.column, end.column)
        let maxCol = max(start.column, end.column)
        let minRow = min(start.row, end.row)
        let maxRow = max(start.row, end.row)

        let x = Double(minCol) / Double(columns)
        let y = Double(minRow) / Double(rows)
        let width = Double(maxCol - minCol + 1) / Double(columns)
        let height = Double(maxRow - minRow + 1) / Double(rows)

        return NormalizedRect(x: x, y: y, width: width, height: height)
    }

    private func selectionRect(in size: CGSize) -> CGRect {
        let origin = CGPoint(x: size.width * rect.x, y: size.height * rect.y)
        let selectionSize = CGSize(width: size.width * rect.width, height: size.height * rect.height)
        return CGRect(origin: origin, size: selectionSize)
    }

    private func selectionRange() -> GridRange {
        guard rect.width > 0, rect.height > 0 else {
            return GridRange(minCol: 0, maxCol: 0, minRow: 0, maxRow: 0)
        }
        let minCol = clamp(Int(floor(rect.x * Double(columns))), min: 0, max: columns - 1)
        let minRow = clamp(Int(floor(rect.y * Double(rows))), min: 0, max: rows - 1)
        let maxCol = clamp(Int(ceil((rect.x + rect.width) * Double(columns)) - 1), min: 0, max: columns - 1)
        let maxRow = clamp(Int(ceil((rect.y + rect.height) * Double(rows)) - 1), min: 0, max: rows - 1)
        return GridRange(minCol: minCol, maxCol: maxCol, minRow: minRow, maxRow: maxRow)
    }

    private func resizeHandles(in selectionRect: CGRect, cellSize: CGSize) -> some View {
        let handles = ResizeHandle.allCases
        return ZStack {
            ForEach(handles, id: \.self) { handle in
                let point = handle.point(in: selectionRect)
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .position(point)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("grid"))
                            .onChanged { value in
                                activeHandle = handle
                                moveStartRect = nil
                                moveStartPoint = nil
                                let gridPoint = value.location
                                let col = clamp(Int(gridPoint.x / cellSize.width), min: 0, max: columns - 1)
                                let row = clamp(Int(gridPoint.y / cellSize.height), min: 0, max: rows - 1)
                                let updated = updatedRange(for: handle, with: GridCell(column: col, row: row))
                                self.rect = normalizedRect(
                                    from: GridCell(column: updated.minCol, row: updated.minRow),
                                    to: GridCell(column: updated.maxCol, row: updated.maxRow)
                                )
                            }
                            .onEnded { _ in
                                activeHandle = nil
                            }
                    )
            }
        }
    }

    private func updatedRange(for handle: ResizeHandle, with cell: GridCell) -> GridRange {
        let current = selectionRange()
        var minCol = current.minCol
        var maxCol = current.maxCol
        var minRow = current.minRow
        var maxRow = current.maxRow

        switch handle {
        case .topLeft:
            minCol = cell.column
            minRow = cell.row
        case .top:
            minRow = cell.row
        case .topRight:
            maxCol = cell.column
            minRow = cell.row
        case .right:
            maxCol = cell.column
        case .bottomRight:
            maxCol = cell.column
            maxRow = cell.row
        case .bottom:
            maxRow = cell.row
        case .bottomLeft:
            minCol = cell.column
            maxRow = cell.row
        case .left:
            minCol = cell.column
        }

        if minCol > maxCol { swap(&minCol, &maxCol) }
        if minRow > maxRow { swap(&minRow, &maxRow) }

        return GridRange(
            minCol: clamp(minCol, min: 0, max: columns - 1),
            maxCol: clamp(maxCol, min: 0, max: columns - 1),
            minRow: clamp(minRow, min: 0, max: rows - 1),
            maxRow: clamp(maxRow, min: 0, max: rows - 1)
        )
    }

    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.max(min, Swift.min(max, value))
    }

    private func clampDouble(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}

private struct GridCell: Equatable {
    let column: Int
    let row: Int
}

private struct GridRange {
    let minCol: Int
    let maxCol: Int
    let minRow: Int
    let maxRow: Int

    func contains(column: Int, row: Int) -> Bool {
        column >= minCol && column <= maxCol && row >= minRow && row <= maxRow
    }
}

private enum ResizeHandle: CaseIterable {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left

    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .top:
            return CGPoint(x: rect.midX, y: rect.minY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
        case .right:
            return CGPoint(x: rect.maxX, y: rect.midY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottom:
            return CGPoint(x: rect.midX, y: rect.maxY)
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .left:
            return CGPoint(x: rect.minX, y: rect.midY)
        }
    }
}
