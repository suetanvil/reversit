# Copyright (C) 2012 Chris Reuter. GPL, No Warranty, see Copyright.txt

require 'board'
require 'history'
require 'movefinder'

# Game represents the entire state of a Reversi game.
class Game
  PLY=3         # Default maximum search depth (less one).

  # Depth to search
  attr_accessor :ply

  def initialize(updater)
    @history    = nil           # The sequence of boards
    @ply        = PLY           # The maximum search depth (less one)
    @updater    = updater       # Display update block to call during search.

    reset
  end

  # Return the current board
  def board
    return @history.current
  end

  # Compute the next move using a MoveFinder
  def computeNextMove(board)
    finder = MoveFinder.new(@updater)
    nextMove = finder.findMove(board, @ply)
    return nextMove
  end

  # Test if the game is over
  def over?
    return board.endOfGame?
  end

  # Return the number of black pieces on the board
  def blackCount
    board.blackCount
  end

  # Return the number of white pieces on the board
  def whiteCount
    board.whiteCount
  end

  # Given a move (for black), return the resulting sequence of boards.
  # This can include multiple boards if one side needs to pass.
  def playTurn(x,y)
    result = []

    Diag.msg "black: #{x},#{y}"
    if !board.validMove?(x,y)
      Diag.msg "Invalid move: #{x},#{y}"
      return []
    end

    whiteBoard = board.withMove(x,y)
    Diag.msg "black's move:\n", board.printable
    result.push whiteBoard

    while true
      whiteMove = computeNextMove(whiteBoard)
      if !whiteMove # No valid move for white
        Diag.msg "white passes."
        blackBoard = whiteBoard.pass
      else
        Diag.msg "white's move: #{whiteMove.first}, #{whiteMove.last}"
        blackBoard = whiteBoard.withMove(whiteMove.first, whiteMove.last)
      end

      result.push blackBoard

      if blackBoard.canMove? || blackBoard.endOfGame? 
        break
      end

      Diag.msg "black passes."
      whiteBoard = blackBoard.pass
    end
    
    @history.addBoard(result[-1])
    Diag.msg("Board value (#{@history.current.turnColour}): ",
             @history.current.evaluation)
    return result
  end

  # Return the number of moves played this game.
  def moveCount
    return @history.pos + 1
  end

  # Test if this is the start of the game.
  def firstMove?
    return @history.atStart?
  end

  # Test if we are at the last board in the game history (i.e. not
  # redoable).
  def latestMove?
    return @history.atEnd?
  end

  # Undo the current move if possible
  def undo
    @history.backward
  end

  # Redo the current move if possible
  def redo
    @history.forward
  end

  # Start a new game.
  def reset
    @history = History.new(Board.startBoard)
  end

  # Save the current board (not game!) to the file at 'filename'.
  # Return true on success, false on failure.
  def save(filename)
    sbrd = @history.current.serialized
    wsz = 0
    File.open(filename, "w") { |fh|
      wsz = fh.write sbrd
    }
    return (wsz == sbrd.size)
  end

  # Load the board at 'filename' and replace the current game with it.
  # Return true on success, false on error.
  def load(filename)
    begin
      brd = File.read(filename)
    rescue Exception => e
      Diag.msg "Exception during load: #{e}"
      return false
    end

    nb = Board.fromSerialized(brd)
    return false unless nb

    @history = History.new(nb)

    return true
  end
end
