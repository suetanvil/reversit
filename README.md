# ReversIt 1.0

ReversIt is a program which plays the game Reversi (aka Othello).  I
wrote it for fun and stopped working on it once it stopped being
fun[1].  As such, it isn't a particulary *good* Othello player[2].

It is written in Ruby and uses Ruby/Tk.  The code is reasonably simple
and readable.


## Installing

To install:

1. Install Ruby/Tk: `gem install 'tk'`

2. Copy the directory tree somewhere.

3. Add the bin/ directory to your PATH and/or write a script to
   invoke `reversit`

### Enabling 'tk` on Ubuntu

Ubuntu installs Tcl/Tk in a non-standard location so the gem can't
find it.  The workaround is to create symlinks:

    sudo ln -s /usr/lib/x86_64-linux-gnu/tcl8.5/tclConfig.sh /usr/lib/tclConfig.sh
    sudo ln -s /usr/lib/x86_64-linux-gnu/tk8.5/tkConfig.sh /usr/lib/tkConfig.sh
    sudo ln -s /usr/lib/x86_64-linux-gnu/libtcl8.5.so.0 /usr/lib/libtcl8.5.so.0
    sudo ln -s /usr/lib/x86_64-linux-gnu/libtk8.5.so.0 /usr/lib/libtk8.5.so.0

Note that you need Tcl/Tk 8.5; 8.6 is not supported by the gem.

[(source)](https://saveriomiroddi.github.io/Installing-ruby-tk-bindings-gem-on-ubuntu/)

## Playing

ReversIt takes a while to start up.  Please be patient.

The player always plays black.

You can save or load individual board configurations.  This does not
save the entire game history but you can start a new game from a saved
board.


## Debugging

ReversIt will print a stream of diagnostic messages to STDOUT (on
Unixish systems, anyway) if the first command-line argument is '-d' or
'--debug'.  Note that there is no proper argument parser so the flag
must be the first argument.


## Legalese

ReversIt is open-source software under the GNU GPLv2 and is
distributed with *NO WARRANTY OF ANY KIND*.




[1]: Actually, it stopped being fun at around the 75% mark but by
that point I'd come too far.

[2]: Then again, neither am I.  For a while, I was consistently being
beaten by an early version that picked its moves at random.
