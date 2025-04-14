
{spawn, exec}  = require 'child_process'
process = require 'process'

SWITCHES = [
  '--help'
  '--version'
  '--verbose'
  '--no-close'
  '-N' # no-close
  '-v' # verbose
  '-h' # help
]

main = (args) ->
  # Check for switches
  for arg in args
    if arg in SWITCHES
      switch arg
        when '--help'
          console.log 'Usage: coffee -c [options] [file]'
          console.log 'Options:'
          console.log '  --help, -h       Show this help message'
          console.log '  --version        Show version information'
          console.log '  --verbose, -v    Enable verbose output'
          console.log '  --no-close, -N   Do not close the process after execution'
          return
        when '--version'
          console.log 'CoffeeScript version 1.12.7'
          return
        when '--verbose', '-v'
          console.log 'Verbose mode enabled'
        when '--no-close', '-N'
          console.log 'No close mode enabled'

main process.argv