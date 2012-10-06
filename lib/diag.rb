# Copyright (C) 2012 Chris Reuter. GPL, No Warranty, see Copyright.txt

# This module contains various debugging and diagnostic tools.  They
# are only enabled if the correct flag is given on the command-line.
module Diag
  @debug = false

  # If debugging is enabled, will throw an exception of 'cond' is
  # false.  
  def Diag.assert(cond)
    return unless @debug
    if cond
      return
    end

    raise "assert() failed."
  end

  # If debugging is enabled, display the arguments on STDOUT.
  def Diag.msg(*args)
    return unless @debug
    args.each {|a| print a}
    puts ""
  end

  # Enable debugging if the first command-line argument in ARGV is
  # '-d' or '--debug'.  Note that this does not use an argument
  # parser; it simply looks for the flag at the start of ARGV.
  def Diag.initDiag
    return unless ARGV.size > 0
    if ARGV[0] == '-d' || ARGV[0] == '--debug'
      @debug = true
    end
    msg "Diagnostic messages enabled."
  end

  # Evaluates its block, times the evaluation and, if debugging is
  # enabled, displays the elapsed time along with message 'desc'.
  # This should not be called in a release version.
  def Diag.time(desc)
    before = Time.new
    yield
    after = Time.new
    msg "Executed '#{desc}' in #{after - before}"
  end
end

