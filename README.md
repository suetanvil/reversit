ReversIt 1.0
------------

ReversIt is a program which plays the game Reversi (aka Othello).  I
wrote it for fun and stopped working on it once it stopped being
fun[1].  As such, it isn't a particulary *good* Othello player[2].

It is written in Ruby 1.9.1 and uses Ruby/Tk.  The code is reasonably
simple and readable.


Installing
==========

To install:

   1. Copy the directory tree somewhere.

   2. Add the bin/ directory to your PATH.

Alternately,

   2. Make a shell script or batch file somewhere in your path that
      launches bin/reversit.

Or

   2. Put bin/reversit somewhere in your path, then edit it so that it
      can still find the rest of the code.


Playing
=======

ReversIt takes a while to start up.  Please be patient.

The player always plays black.

You can save or load individual board configurations.  This does not
save the entire game history but you can start a new game from a saved
board.


Debugging
=========

ReversIt will print a stream of diagnostic messages to STDOUT (on
Unixish systems, anyway) if the first command-line argument is '-d' or
'--debug'.  Note that there is no proper argument parser so the flag
must be the first argument.


Legalese
========

ReversIt is open-source software under the GNU GPLv2 and is
distributed with *NO WARRANTY OF ANY KIND*.




[1]: Actually, it stopped being fun at around the 75% mark but by
that point I'd come too far.

[2]: Then again, neither am I.  For a while, I was consistently being
beaten by an early version that picked its moves at random.
