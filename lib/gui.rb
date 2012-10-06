# Copyright (C) 2012 Chris Reuter. GPL, No Warranty, see Copyright.txt

require 'tk'
require 'tkextlib/tile'

require 'game'
require 'diag'

# This class implements the user interface and drives the action.
class Gui
  TIMEOUT = 1000
  TILEBG = "green"
  HILIGHTBG = "yellow"
  FILETYPES = [ ['Board Files', '.board'], ['ALL Files', '*'] ]

  def initialize

    # Board state
    @tiles = {                    # Loaded GIF images
      black: fetch("blackpiece"),
      blank: fetch("blank"),
      legal: fetch("legal"),
      white: fetch("whitepiece")
    }
    @slots              = nil     # Array of board squares
    @currentView =                # Names of images stored in @slots
      Array.new(8) {Array.new(8, :blank)}

    @hilightOn          = false   # If true, hilight all board changes
    @disableClick       = false   # If true, ignore all clicks on the board

    # Tk widgets
    @scoreLabel         = nil
    @countLabel         = nil
    @undoButton         = nil
    @redoButton         = nil
    @restartButton      = nil
    @loadButton         = nil
    @saveButton         = nil
    @root               = nil

    # The game object
    @game = Game.new(proc{Tk.update})
  end

  # Open the window and begin the game.
  def go
    initWin
    updateDisplay
    Tk.mainloop
  end

  # Undo the current move.  Called from the 'Undo' button.
  def undo
    return if @game.firstMove?  # Shouldn't be possible
    @game.undo
    updateDisplay
  end

  # Redo the previosly-undone move.  Called from the 'Redo' button.
  def redo
    return if @game.latestMove?  # Shouldn't be possible
    @game.redo
    updateDisplay
  end

  # Prompt for confirmation and if given, reset the game object back
  # to the initial board.
  def newGame
    status = Tk.messageBox ({
                              icon: 'question',
                              type: 'okcancel',
                              default: 'cancel',
                              message: "Are you sure you want to start a new game?",
                              title: "Confirm New Game"
     })
    return unless status == 'ok'
    @game.reset
    updateDisplay
  end

  # Prompt the user for a filename and if one is selected, save the
  # current board to it.
  def saveBoard
    path = Tk.getSaveFile defaultextension: '.board', filetypes: FILETYPES
    return unless path != ''
    if !@game.save(path)
      Tk.messageBox ({
                       icon: 'error',
                       type: 'ok',
                       default: 'ok',
                       message: "Error saving file '#{path}",
                       title: "File Error!"
                     })
      return
    end
    Diag.msg "Saved board to '#{path}'"
  end

  # Get the user to select a file and if successful, replace the
  # current game with one starting at the board it contains.
  def loadBoard
    path = Tk.getOpenFile defaultextension: '.board', filetypes: FILETYPES
    return unless path != ''
    if !@game.load(path)
      Tk.messageBox ({
                       icon: 'error',
                       type: 'ok',
                       default: 'ok',
                       message: "Error loading file '#{path}",
                       title: "File Error!"
                     })
      return
    end
    Diag.msg "Loaded board '#{path}':\n", @game.board.printable
    updateDisplay
  end
    

  private

  # Place a black piece at (x,y) if allowed.  This is called by the
  # mouse-click event handler.
  def withMove(x,y)
    return unless @game.board.validMove?(x,y)

    # Display the user's move and start computing the countering move
    # while the hilights time out.
    showMoveSeq(@game.board.withMove(x,y)) {
      boards = @game.playTurn(x,y)
      boards.shift
      boards
    }

    updateDisplay(false)
  end

  # Make the display consistent with the internalstate.  If
  # 'showBoard' is false, the board pieces are not touched.
  def updateDisplay(showBoard = true)
    displayBoard(@game.board) if showBoard    
    updateStats
    updateCount
    updateButtons
  end

  # Update the enabledness of the Undo and Redo buttons.
  def updateButtons
    @undoButton.configure state: @game.firstMove? ?  'disabled' : 'normal'
    @redoButton.configure state: @game.latestMove? ? 'disabled' : 'normal'
  end

  # Update the text of the stats bar at the bottom-left of the window.
  def updateStats
    b = @game.blackCount
    w = @game.whiteCount
    text = sprintf "Dark: %2d / Light: %2d", b, w

    if @game.over?
      preamble = "Tie game!"
      preamble = "Dark wins!" if b > w
      preamble = "Light wins!" if w > b

      text = preamble + " " + text
    end

    @scoreLabel.configure text: text
  end

  # Update the move count at the bottom-right of the window
  def updateCount
    count = sprintf "Moves: %2d", @game.moveCount - 1
    @countLabel.configure text: count
  end

  # Displays a sequence of moves.
  #
  # Each move is highlighted (i.e. the background colour changes
  # briefly) and the next move does not occur until the highlighting
  # has disappeared.  This makes it easier for the viewer to follow
  # the action.
  #
  # Argument 'firstBoard' is the first move to display and the block
  # is evaluated to return the remaining moves in an array.
  # 'showMoveSeq' immediately displays and highlights the first move,
  # then evaluates the block.  This makes the first move (which is the
  # user's selection) appear immediately and allows us to start
  # finding the next move during the delay.
  def showMoveSeq(firstBoard)
    disableUI
    before = Time.now

    hilighted {displayBoard(firstBoard)}
    boards = yield
    hilightingDone = (Time.now - before) > 1

    count = hilightingDone ? 0 : 1
    boards.each do |b|
      Tk.after(count * TIMEOUT) {hilighted{ displayBoard(b) } }
      count += 1
    end

    Tk.after (count * TIMEOUT) {enableUI}
  end

  # Evaluate teh block with move highlighting turned on.
  def hilighted
    oldval = @hilightOn
    @hilightOn = true
    yield
    @hilightOn = oldval
  end

  # Display 'board' on the GUI.
  def displayBoard(board)
    for x in 0 .. 7
      for y in 0 .. 7
        showSquare(board, x, y)
      end
    end
  end

  # Display the square at (x,y) in 'board' on the GUI.  Highlight the
  # change if highlighting is switched on.
  def showSquare(board, x, y)
    pos = board.turnColour == :black ? board.atOrHint(x,y) : board.at(x,y)

    if @currentView[x][y] == pos
      return
    end
    @currentView[x][y] = pos

    @slots[x][y].configure(image: @tiles[pos])

    if (@hilightOn && (pos == :white || pos == :black))
      @slots[x][y].configure(bg: HILIGHTBG)
      Tk.after(TIMEOUT) {@slots[x][y].configure(bg:TILEBG)}
    end
  end

  # Create and fill the main GUI window.
  def initWin
    gui = self  # the blocks sometimes override 'self'
    lg = @game  # ditto

    @root = TkRoot.new {title "ReversIt!"}

    bbar = TkFrame.new(@root) {
      pack side: 'top', fill: 'both'
    }

    @undoButton = TkButton.new(bbar) {
      text "Undo"
      pack side: 'left', anchor: 'n'
      command (proc {gui.undo})
    }

    @redoButton = TkButton.new(bbar) {
      text "Redo"
      pack side: 'left', anchor: 'n'
      command (proc {gui.redo})
    }

    @restartButton = TkButton.new(bbar) {
      text "New Game"
      pack side: 'right', anchor: 'n'
      command (proc {gui.newGame})
    }

    @saveButton = TkButton.new(bbar) {
      text "Save Board"
      pack side: 'right', anchor: 'n'
      command (proc {gui.saveBoard})
    }

    @loadButton = TkButton.new(bbar) {
      text "Load Board"
      pack side: 'right', anchor: 'n'
      command (proc {gui.loadBoard})
    }

    # The 'depth' control (second from the top)
    ply = TkVariable.new
    ply.value = @game.ply

    dbar = TkFrame.new(@root) { # outer container
      pack side: 'top', fill: 'both'
    }

    rbar = TkFrame.new(dbar) {  # centered inner container
      pack side: 'top'
    }

    TkLabel.new(rbar) {
      text "Depth:"
      pack side: 'left'
    }

    [1,2,3,4,5,6,7].each do |depth|
      TkRadioButton.new(rbar) {
        text "#{depth+1}"
        variable ply
        value depth
        command proc{Diag.msg "Ply: '#{ply.value}'"; lg.ply = ply.value.to_i}
        pack side: 'left'
      }
    end

    # The game board
    board = TkFrame.new(@root) {
      background "black"
      pack side: 'top', fill: 'both'
    }

    @slots = Array.new(8) {Array.new(8)}
    img = @tiles[:blank]
    for y in 0 .. 7
      for x in 0 .. 7
        @slots[x][y] = TkLabel.new(board) {
          image img
          background TILEBG
          borderwidth 2
          relief 'flat'

          pw = 2
          px = (x == 0) ? pw : 0
          py = (y == 0) ? pw : 0

          grid column: x, row: y, padx: [px, pw], pady: [py, pw] # Slow!
        }
        bindMouse(x, y)
      end
    end

    # The score bar
    sbar = TkFrame.new(@root) {
      pack side: 'top', fill: 'both'
    }

    @scoreLabel = TkLabel.new(sbar) {
      text "XXXXXXXXXXXXX"
      pack side: 'left', anchor: 'n'
    }

    @countLabel = TkLabel.new(sbar) {
      text "XXXXXXXXXXXXX"
      pack side: 'right', anchor: 'n'
    }

  end

  # Add a mouse-down event to the widget at (x,y)
  def bindMouse(x,y)
    @slots[x][y].bind('ButtonPress-1') {withMove(x,y) unless @disableClick}
  end

  # Retrieve an image file from the 'img' subdirectory and return a
  # TkPhotoImage object containing it.
  def fetch(name)
    path = [File.dirname(__FILE__), 'img', name + ".gif"].join(File::Separator)
    img = TkPhotoImage.new(file: path)
    return img
  end

  # Disable all UI components.
  def disableUI
    @disableClick = true
    @undoButton.configure    state: 'disabled'
    @redoButton.configure    state: 'disabled'
    @restartButton.configure state: 'disabled'
    @loadButton.configure    state: 'disabled'
    @saveButton.configure    state: 'disabled'
    @root.cursor 'watch'
  end

  # Enable all UI components as appropriate
  def enableUI
    @disableClick = false
    @restartButton.configure state: 'active'
    @loadButton.configure    state: 'active'
    @saveButton.configure    state: 'active'
    @root.cursor ''
    updateButtons()
  end

end





