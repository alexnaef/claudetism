import SwiftUI

struct GridEditorView: View {
    @Binding var rect: NormalizedRect

    private let columns = 24
    private let rows = 16

    @State private var dragStart: GridCell?
    @State private var moveStartRect: NormalizedRect?
    @State private var moveStartPoint: CGPoint?
    @State private var activeHandle: ResizeHandle?
    @State private var dragMode: DragMode?
    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cellSize = CGSize(width: size.width / CGFloat(columns), height: size.height / CGFloat(rows))
            let selection = selectionRange()
            let selectionRect = selectionRect(in: size)

            ZStack {
                dotGrid(size: size, cellSize: cellSize, selection: selection)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(isDragging ? 0.18 : 0.08))
                    .background(Color.black.opacity(0.001))
                    .frame(width: selectionRect.size.width, height: selectionRect.size.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
                    .contentShape(RoundedRectangle(cornerRadius: 8))

                resizeHandles(in: selectionRect)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("grid"))
                    .onChanged { value in
                        if dragMode == nil {
                            dragMode = determineDragMode(start: value.startLocation, selectionRect: selectionRect)
                            moveStartRect = rect
                            moveStartPoint = value.startLocation
                            dragStart = cell(for: value.startLocation, cellSize: cellSize)
                        }
                        isDragging = true

                        switch dragMode {
                        case .resize(let handle):
                            activeHandle = handle
                            let gridPoint = value.location
                            let col = clamp(Int(gridPoint.x / cellSize.width), min: 0, max: columns - 1)
                            let row = clamp(Int(gridPoint.y / cellSize.height), min: 0, max: rows - 1)
                            let updated = updatedRange(for: handle, with: GridCell(column: col, row: row))
                            rect = normalizedRect(
                                from: GridCell(column: updated.minCol, row: updated.minRow),
                                to: GridCell(column: updated.maxCol, row: updated.maxRow)
                            )
                        case .move:
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
                        case .newSelection:
                            let startCell = dragStart ?? cell(for: value.startLocation, cellSize: cellSize)
                            dragStart = startCell
                            let current = cell(for: value.location, cellSize: cellSize)
                            rect = normalizedRect(from: startCell, to: current)
                        case .none:
                            break
                        }
                    }
                    .onEnded { _ in
                        dragStart = nil
                        dragMode = nil
                        activeHandle = nil
                        moveStartRect = nil
                        moveStartPoint = nil
                        isDragging = false
                    }
            )
        }
        .background(Color.black.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .coordinateSpace(name: "grid")
    }

    private func dotGrid(size: CGSize, cellSize: CGSize, selection: GridRange) -> some View {
        let baseDot = min(cellSize.width, cellSize.height)
        return VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { col in
                        let isSelected = selection.contains(column: col, row: row)
                        let dotSize = baseDot * (isSelected ? 0.8 : 0.35)
                        RoundedRectangle(cornerRadius: dotSize * 0.2)
                            .fill(isSelected ? Color.accentColor : Color.white.opacity(0.2))
                            .frame(width: dotSize, height: dotSize)
                            .frame(width: cellSize.width, height: cellSize.height)
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

    private func determineDragMode(start: CGPoint, selectionRect: CGRect) -> DragMode {
        if let handle = handleHitTest(at: start, selectionRect: selectionRect) {
            return .resize(handle)
        }
        if selectionRect.contains(start) {
            if NSEvent.modifierFlags.contains(.option) {
                return .move
            }
            return .newSelection
        }
        return .newSelection
    }

    private func handleHitTest(at point: CGPoint, selectionRect: CGRect) -> ResizeHandle? {
        let hitRadius: CGFloat = 10
        for handle in ResizeHandle.allCases {
            let handlePoint = handle.point(in: selectionRect)
            let dx = point.x - handlePoint.x
            let dy = point.y - handlePoint.y
            if (dx * dx + dy * dy) <= hitRadius * hitRadius {
                return handle
            }
        }
        let edgeThreshold: CGFloat = 6
        if abs(point.x - selectionRect.minX) <= edgeThreshold && point.y >= selectionRect.minY && point.y <= selectionRect.maxY {
            return .left
        }
        if abs(point.x - selectionRect.maxX) <= edgeThreshold && point.y >= selectionRect.minY && point.y <= selectionRect.maxY {
            return .right
        }
        if abs(point.y - selectionRect.minY) <= edgeThreshold && point.x >= selectionRect.minX && point.x <= selectionRect.maxX {
            return .top
        }
        if abs(point.y - selectionRect.maxY) <= edgeThreshold && point.x >= selectionRect.minX && point.x <= selectionRect.maxX {
            return .bottom
        }
        return nil
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

    private func resizeHandles(in selectionRect: CGRect) -> some View {
        let handles = ResizeHandle.allCases
        return ZStack {
            ForEach(handles, id: \.self) { handle in
                let point = handle.point(in: selectionRect)
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .position(point)
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

private enum DragMode {
    case newSelection
    case move
    case resize(ResizeHandle)
}
