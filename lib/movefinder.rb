# Copyright (C) 2012 Chris Reuter. GPL, No Warranty, see Copyright.txt

require 'board'
require 'diag'

# This class implements code to find the best move for a player, given
# a board.  It implements a basic minimax search with alpha-beta
# pruning.  Since this tends to be a CPU-intensive process, it will
# also periodically evaluate a caller-provided proc during the search
# in order to maintain a sense of interactivity in the program.
class MoveFinder
  UPDATE_PER = 300
  POSINF     = 1.0/0.0
  NEGINF     = -1.0/0.0

  # Initialize the object.  'updater' is either nil or a proc which
  # will be called every UPDATE_PER board evaluations.
  def initialize(updater)
    @count = 0
    @updater = updater
  end

  # Return the best move on 'board' for 'board.turnColour'.  Returns
  # nil if no move is possible.
  def findMove(board, depth)
    return nil unless board.canMove?

    # We do half of an alpha-beta search for the best move.  Since
    # we're maximizing, we don't worry about beta.  Also, we need to
    # keep track of the best move as well as its associated score
    # here but not in score().
    best = nil
    alpha = NEGINF
    @count = 1
    for move in board.validMoves
      newBoard = board.withMove(move.first, move.last)
      newScore = score newBoard, depth, board.turnColour, alpha, POSINF
      if newScore >= alpha
        alpha = newScore
        best = move
      end
    end

    Diag.msg "Searched #{@count} boards (#{depth+1} ply).  Match: #{best}. " +
      "Score: #{alpha}"
    return best
  end

  private

  # Compute the score of 'board' to depth 'depth'.  'maxColour' is the
  # color being maximized.  This implements a simple minimax search
  # with alpha-beta pruning.
  def score(board, depth, maxColour, alpha, beta)
    maximize = (board.turnColour == maxColour)

    updateMaybe # I just called you, and this is crazy...

    if (depth == 0 || board.validMoves.size == 0)
      # Board evaluation wrt. maxColour:
      return board.evaluation if maximize
      return -board.evaluation
    end

    # Search the children for the best move
    for move in board.validMoves
      nextBoard = board.withMove(move.first, move.last)
      nextScore = score(nextBoard, depth - 1, maxColour, alpha, beta)

      # Update the alpha or beta values
      if maximize
        alpha = [alpha, nextScore].max
      else
        beta =  [beta,  nextScore].min
      end

      # Since alpha < range < beta, we can bail if there are no
      # possible values.
      break if beta <= alpha
    end

    # And return the score.
    return maximize ? alpha : beta
  end

  # Increment @count and periodically call @updater (if defined).
  # UPDATE_PER defines the period.  (@updater normally updates the Tk
  # event queue so that the screen will refresh during long searches.)
  def updateMaybe
    @count += 1
    @updater.call() if @updater && (@count % UPDATE_PER) == 0
  end
end
