import Foundation

enum Direction: CaseIterable {
    case up
    case left
    case right
    case down
}

struct Position: Hashable {
    var row: Int
    var column: Int
}

class Board {
    private var board: [[String]]
    private var emptyTilePosition: Position
    private(set) var parent: Board?
    private var sizeOfBoard: Int
    var index: Int

    init(board: [String], sizeOfBoard: Int) {
        self.board = board.chunked(into: sizeOfBoard)
        let emptyTileIndex = board.firstIndex(of: "")!
        self.emptyTilePosition = Position(
            row: emptyTileIndex / sizeOfBoard,
            column: emptyTileIndex % sizeOfBoard
        )
        self.parent = nil
        self.sizeOfBoard = sizeOfBoard
        self.index = 0
    }

    init?(board: Board, direction: Direction) {
        self.board = board.board
        self.emptyTilePosition = board.emptyTilePosition
        self.parent = board
        self.sizeOfBoard = board.sizeOfBoard
        self.index = board.index + 1

        if !moveEmptySpaceTo(direction: direction) {
            return nil
        }
    }

    func manhattanDistance(from otherBoard: Board) -> Int {
        if self == otherBoard {
            return 0
        }

        let flatBoard = Array(board.joined())
        let flatOtherBoard = Array(otherBoard.board.joined())

        return flatBoard.enumerated().reduce(0) { partialResult, value in
            let valueRow = value.offset / sizeOfBoard
            let valueColumn = value.offset % sizeOfBoard

            let otherBoardIndex = flatOtherBoard.firstIndex(of: value.element)!
            let otherBoardRow = otherBoardIndex / sizeOfBoard
            let otherBoardColumn = otherBoardIndex % sizeOfBoard

            return abs(otherBoardRow - valueRow) + abs(otherBoardColumn - valueColumn)
        }
    }

    func moveEmptySpaceTo(direction: Direction) -> Bool {
        switch direction {
        case .up:
            guard emptyTilePosition.row - 1 > 0 else {
                return false
            }
            board[emptyTilePosition.row][emptyTilePosition.column] = board[emptyTilePosition.row - 1][emptyTilePosition.column]
            board[emptyTilePosition.row - 1][emptyTilePosition.column] = ""
            emptyTilePosition.row -= 1

        case .left:
            guard emptyTilePosition.column - 1 > 0 else {
                return false
            }
            board[emptyTilePosition.row][emptyTilePosition.column] = board[emptyTilePosition.row][emptyTilePosition.column - 1]
            board[emptyTilePosition.row][emptyTilePosition.column - 1] = ""
            emptyTilePosition.column -= 1

        case .right:
            guard emptyTilePosition.column + 1 < sizeOfBoard else {
                return false
            }
            board[emptyTilePosition.row][emptyTilePosition.column] = board[emptyTilePosition.row][emptyTilePosition.column + 1]
            board[emptyTilePosition.row][emptyTilePosition.column + 1] = ""
            emptyTilePosition.column += 1

        case .down:
            guard emptyTilePosition.row + 1 < sizeOfBoard else {
                return false
            }
            board[emptyTilePosition.row][emptyTilePosition.column] = board[emptyTilePosition.row + 1][emptyTilePosition.column]
            board[emptyTilePosition.row + 1][emptyTilePosition.column] = ""
            emptyTilePosition.row += 1


        }
        return true
    }
}

extension Board: Equatable, Hashable {
    static func == (lhs: Board, rhs: Board) -> Bool {
        lhs.board == rhs.board
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(board)
        hasher.combine(emptyTilePosition)
    }
}

// Array.swift
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

protocol Solver {
    init(solve: Board, withEndResult: Board)
    func solve() async -> [Board]
}

class DFSSolver: Solver {
    private var initialBoard: Board
    private var finalBoard: Board
    private var visited = Set<Board>()
    private var queue = Array<Board>()
    private var maximumManhattanDistance: Int

    required init(solve initialBoard: Board, withEndResult finalBoard: Board) {
        self.initialBoard = initialBoard
        self.finalBoard = finalBoard
        maximumManhattanDistance = initialBoard.manhattanDistance(from: finalBoard)
    }

    func solve() -> [Board] {
        var board: Board? = initialBoard
        while board != nil && board != finalBoard {
            if !visited.contains(board!) {
                for direction in Direction.allCases {
                    if let newBoard = Board(board: board!, direction: direction), newBoard.index <= 6 {
                        let newManhattanDistance = newBoard.manhattanDistance(from: board!)
                        if newManhattanDistance <= maximumManhattanDistance {
                            maximumManhattanDistance = min(maximumManhattanDistance, newManhattanDistance)
                            queue.append(newBoard)
                        }
                    }
                }
                visited.insert(board!)
            }
            board = queue.first
            if !queue.isEmpty {
                queue.removeFirst()
            }
        }
        if board == nil {
            return []
        }

        var result: [Board] = []
        while board != nil {
            result.append(board!)
            board = board!.parent
        }
        return result
    }
}
