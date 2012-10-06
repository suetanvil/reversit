# Copyright (C) 2012 Chris Reuter. GPL, No Warranty, see Copyright.txt

# An instance of History implements the undo history of a game.
#
# History is a list of moves with a pointer to the current board
# (typically, the latest move.)  This pointer can be moved forward and
# backward.  New boards are always added after the pointer, deleting
# subsequent boards if necessary, and the pointer is advanced to it.
class History
  attr_reader :pos              # The index of the current board

  def initialize(board)
    @boards = [board]           # The board list with first board
    @pos = 0                    # Pointer to the current board
  end

  # Add 'aBoard' to the history.  'aBoard' is inserted after 'current'
  # and 'pos' is advanced to point to it, making it the new 'current'.
  # If 'pos' was pointing to the last board, all following boards are
  # first deleted, making 'aBoard' the latest board.
  def addBoard(aBoard)
    if aBoard.turnColour != :black
      return
    end

    if !atEnd?
      @boards = @boards[0..@pos]
    end

    @boards.push(aBoard)
    @pos = @boards.size - 1
  end

  # Test if 'current' is the first board.
  def atStart?
    return @pos == 0
  end

  # Test if 'current' is the last board
  def atEnd?
    return @pos == @boards.size - 1
  end

  # Move 'current' to one board previous (if possible)
  def backward
    if !atStart?
      @pos -= 1
    end
  end

  # Move 'current' to one board ahead (if possible)
  def forward
    if !atEnd?
      @pos += 1
    end
  end

  # Return the current board
  def current
    return @boards[@pos]
  end
end
