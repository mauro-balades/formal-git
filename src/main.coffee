
{spawn, exec}  = require 'child_process'
process = require 'process'
{version} = require './package.json'

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
  commitMessage = ""
  bugId = ""
  verbose = false
  noClose = false
  for arg in args
    if arg in SWITCHES
      switch arg
        when '--help'
          console.log 'Usage: fo -c [options] [file]'
          console.log 'Options:'
          console.log '  --help, -h       Show this help message'
          console.log '  --version        Show version information'
          console.log '  --verbose, -v    Enable verbose output'
          console.log '  --no-close, -N   Do not close the process after execution'
          return
        when '--version'
          console.log "Version: #{version}"
          return
        when '--verbose', '-v'
          verbose = true
        when '--no-close', '-N'
          noClose = true

main process.argv