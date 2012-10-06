# Copyright (C) 2012 Chris Reuter. GPL, No Warranty, see Copyright.txt

require 'history'
require 'diag'

# Instances of Board represent a particular board state (i.e. board
# with pieces plus whose turn it is).  Board instances are publicly
# immutable, although they do have some internal caches.  Typically,
# you get the first instance using 'startBoard' and create new
# instances by calling 'withMove'.
class Board
  attr_reader :turnColour

  def initialize(turnColour, pieces = Array.new(64) {:blank})
    Diag.assert(turnColour == :black || turnColour == :white)

    # Instance values
    @turnColour = turnColour
    @pieces = Array.new(pieces)

    # Lazy values
    @blackCount = nil
    @whiteCount = nil
    @validMoves = nil
    @evaluation = nil
  end

  # Return an instance of Board initialized to the starting board of a
  # game.
  def self.startBoard
    board = Array.new(64, :blank)

    setAt(board, 3, 3, :white)
    setAt(board, 4, 4, :white)
    setAt(board, 4, 3, :black)
    setAt(board, 3, 4, :black)

    return self.new(:black, board)
  end

  # Return the colour of the piece at (x,y)
  def at(x,y)
    @pieces[x + (y*8)]
  end

  # Like 'at' but returns :legal if the location is a legal move.
  def atOrHint(x,y)
    piece = at(x,y)
    return :legal if (piece == :blank && validMove?(x,y))
    return piece
  end
    
  # Test if the piece at (x,y) is the opponent to @turnColour.
  def opponentAt?(x, y)
    piece = at(x,y)
    return piece == otherColour
  end

  # Test if the piece at (x,y) is the same as @turnColour.
  def friendlyAt?(x,y)
    return at(x,y) == @turnColour
  end

  # Test if (x,y) is a valid board position.
  def onboard?(x, y)
    return x >= 0 && x < 8 && y >= 0 && y < 8
  end

  # Evaluate the block on the coordinates of each valid square.
  def eachSquare
    for y in 0 .. 7
      for x in 0 .. 7
        yield(x,y)
      end
    end
  end

  # Return all coordinates around (x,y) for which the block
  # returns true.
  def selectAround(x, y)
    result = []
    eachAround(x,y) {|xi, yi| result.push [xi, yi] if yield(xi, yi) }
    return result
  end

  # Return the list of valid moves allowed in this board for
  # @turnColour
  def validMoves
    setValidMoves unless @validMoves
    return Array.new(@validMoves)
  end

  # Test if (x,y) is a valid move for @turnColour.
  def validMove?(x,y)
    setValidMoves unless @validMoves
    @validMoves.each { |m| return true if m ==[x, y] }
    return false
  end

  # Test if there are any valid moves available to @turnColour in this
  # board.
  def canMove?
    setValidMoves unless @validMoves
    return @validMoves.size > 0
  end

  # Test if there are no more moves possible for either player from
  # this board.
  def endOfGame?
    return !canMove? && !pass.canMove?
  end

  # Return the number of black pieces on the board.
  def blackCount
    countPieces unless @blackCount
    return @blackCount
  end

  # Return the number of white pieces on the board.
  def whiteCount
    countPieces unless @whiteCount
    return @whiteCount
  end

  # Return the number of pieces matching @turnColour on the board.
  def friendlyCount
    return @turnColour == :black ? blackCount : whiteCount
  end

  # Return the number of pieces NOT matching @turnColour on the board.
  def opponentCount
    return @turnColour == :white ? blackCount : whiteCount
  end

  # Return the player colour that is not @turnColour.
  def otherColour
    return @turnColour == :black ? :white : :black;
  end

  # Return the board resulting from placing a piece at (x,y) (which
  # *must* be valid.)
  def withMove(x,y)

    # Since boards are immutable, we need to make a copy of the
    # contents and manipulate that before putting the entries in a new
    # board.
    np = Array.new(@pieces)
    self.class.setAt(np, x, y, @turnColour)

    flips = []
    eachAround(x,y) { |xi, yi| flips += flipList(x, y, xi, yi)}
    Diag.assert flips.size > 0

    for coord in flips
      self.class.setAt(np, coord.first, coord.last, @turnColour)
    end

    return Board.new(otherColour, np)
  end

  # Return the board resulting from not making a move.  Specifically,
  # it's the identical board but with @turnColour flipped.
  def pass
    return Board.new otherColour, @pieces
  end

  # Display an ASCII representation of this board.
  def printable
    result = ""

    for y in 0..7
      for x in 0..7
        case at(x, y)
        when :black
          result += "*"
        when :white
          result += "O"
        when :blank
          result += validMove?(x,y) ? "_" : "-";
        else
          result += "?"
        end
      end
      result += "\n"
    end

    return result
  end

  # Return a string description of this board that self.fromSerialized
  # can use to recreate the board.
  def serialized
    result = @turnColour == :black ? "*" : "0"
    result += "\n"
    result += printable
    return result
  end

  # Given a serialized board (boardString), return a new Board
  # containing the layout.  If 'boardString' is malformed, returns nil
  # instead.
  def self.fromSerialized(boardString)
    # Split into lines
    lines = boardString.split
    return nil unless lines.size == 9
    
    # Get the turn colour
    bc = lines.shift
    tc = (bc == '*') ? :black : (bc == '0' ? :white : nil) 
    return nil unless tc

    # Get the actual board
    board = Array.new(64, :blank)
    y = 0
    for line in lines
      return nil unless line.size == 8
      x = 0
      for c in line.split("")
        case c
        when "O"
          setAt(board, x, y, :white)
        when "*"
          setAt(board, x, y, :black)
        when "-", "_"
        else
          return nil
        end
        x += 1
      end
      y += 1
    end

    # And return the new board
    return self.new(tc, board)
  end


  # Return the evaluation value.  Higher is better for @turnColour.
  def evaluation
    @evaluation = computeEvaluation unless @evaluation
    return @evaluation
  end

  private

  # Follow the vector from startx,starty and endx,endy (which must be
  # adjacent) further down to see if it contains 1 or more opponent
  # pieces followed by a player piece.  If so, return a list of
  # coordinates of pieces that will be toggled if a piece is placed at
  # (x,y).  If not, return an empty array.
  def flipList(startx, starty, endx, endy)
    dirx = endx - startx
    diry = endy - starty
    x = startx + dirx
    y = starty + diry
    points = [ [x,y] ]

    while onboard?(x, y) && opponentAt?(x, y)
      x += dirx
      y += diry
      points.push([x,y])
    end

    return [] unless onboard?(x,y) && friendlyAt?(x, y) && points.size > 1
    return points
  end

  # Test if placing a piece at (startx, starty) would cause one or
  # more pieces to be flipped in the direction indicated by (endx,
  # endy).  (endx, endy) must be adjacent to (startx, starty) and is
  # used to indicate the direction.
  def candidateDir?(startx, starty, endx, endy)
    return flipList(startx, starty, endx, endy).size > 0
  end

  # Compute piece counts.
  def countPieces
    counts = {black: 0, white: 0, blank: 0}
    eachSquare { |x, y| counts[at(x,y)] += 1 }
    @blackCount = counts[:black]
    @whiteCount = counts[:white]
  end

  # Evaluate the block for each square adjacent to (x,y)
  def eachAround(x, y)
    left   = [x - 1, 0].max
    right  = [x + 1, 7].min
    top    = [y - 1, 0].max
    bottom = [y + 1, 7].min

    for yi in top .. bottom
      for xi in left .. right
        next if (x == xi && y == yi)
        yield(xi, yi)
      end
    end
  end

  # Sets the value of array at (x,y) to piece.
  def self.setAt(array, x, y, piece)
    array[x + (y*8)] = piece
  end

  # Fill the @validMoves variable with the list of valid moves.
  def setValidMoves
    @validMoves = []
    eachSquare {|x,y| @validMoves.push([x,y]) if privValidMove?(x,y)}
  end

  # Compute if (x,y) is a valid move for @turnColour WITHOUT using
  # @validMoves.
  def privValidMove?(x, y)
    if at(x,y) != :blank
      return false
    end

    candidates = selectAround(x,y) {|xi, yi| 
      return true if candidateDir?(x, y, xi, yi)
    }
    return false
  end

  # Return an array containing the coordinates of all the non-corner
  # edge positions on the board.
  def edges
    edges = []
    for x in 1 .. 6
      edges.push [x,0], [x,7], [0,x], [7,x]
    end

    return edges
  end

  # Return an array containing the coordinates of all the corner
  # pieces.
  def corners
    return [ [0,0], [0,7], [7,0], [7,7] ]
  end

  # Return the difference in counts between @turnColour and opponent
  # pieces at the locations in 'points', normalized to a range between
  # -1.0 and 1.0.
  def spotCount(points)
    count = 0.0
    for e in points
      x, y = e
      count += 1 if friendlyAt?(x,y)
      count -= 1 if opponentAt?(x,y)
    end

    return count / points.size
  end

  # Return the fraction of corners I control vs corners the opponent
  # controls, normalized to a range between -1.0 and 1.0
  def cornerCount
    return spotCount(corners)
  end

  # Return the fraction of edges I control vs. the fraction the
  # opponent controls, normalized to a range of -1.0 and 1.0.
  def edgeCount
    return spotCount(edges)
  end
  
  # Return the fraction of pieces I control vs. the fraction the
  # opponent controls, normalized to a range of -1.0 and 1.0.
  def pieceCount
    return (friendlyCount - opponentCount) / 64.0
  end

  # Return the evaluation of an endgame piece.  Results are infinity,
  # -infinity or 0 for wine, loss and tie respectively.  Because those
  # are the only cases that matter.
  def finalEvaluation
    return 0.0 if blackCount == whiteCount

    result = 1.0/0.0    # positive infinity
    result = -result if opponentCount > friendlyCount
    return result
  end

  # Compute and return the evaluation function.  This result is
  # computed once and then cached in @evaluation by the caller.
  def computeEvaluation
    return finalEvaluation if endOfGame?
    return 60*cornerCount + 10*edgeCount + pieceCount
  end

end

