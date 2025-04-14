
{spawn, exec}  = require 'child_process'
process = require 'process'
{version} = require '../package.json'

SWITCHES = [
  '--help'
  '--version'
  '--verbose'
  '--no-close'
  '-N' # no-close
  '-v' # verbose
  '-h' # help
  '-V' # version
]

removeBinFromArgs = (args) ->
  # Remove the first two arguments if they are the path to the binary
  if args[0] == process.execPath and args[1] == __filename
    return args.slice(2)
  else
    return args

getCorrectCommitType = (commitType) ->
  # Validate the commit type
  validCommitTypes = ['feat', 'fix', 'docs', 'style', 'refactor', 'perf', 'test', 'chore']
  shortToLong = {
    'f': 'feat'
    'fi': 'fix'
    'd': 'docs'
    's': 'style'
    'r': 'refactor'
    'p': 'perf'
    't': 'test'
    'c': 'chore'
  }
  if shortToLong[commitType]
    commitType = shortToLong[commitType]
  if commitType in validCommitTypes
    return commitType
  else
    throw new Error "Invalid commit type: #{commitType}. Valid types are: #{validCommitTypes.join(', ')}"

getCommitTemplate = ->
  # Get the commit template from a .formal-git file
  templateFile = '.formal-git'
  if fs.existsSync templateFile
    template = fs.readFileSync templateFile, 'utf8'
    return template
  else
    return "{type}({components}) - {bugId} - {message}"

getChangedFiles = ->
  # Get the list of changed files
  changedFiles = []
  exec 'git diff --cached --name-only', (error, stdout, stderr) ->
    if error
      console.error "Error getting changed files: #{error.message}"
      return
    changedFiles = stdout.split('\n').filter (file) -> file.length > 0
    if changedFiles.length == 0
      console.log "No files to commit"
      return
    else
      console.log "Changed files: #{changedFiles.join(', ')}"
      return changedFiles


main = (args) ->
  args = args
  commitType = ""
  commitMessage = ""
  bugId = ""
  verbose = false
  noClose = false
  extraArgs = []
  for arg in args
    if arg in SWITCHES
      switch arg
        when '--help'
          console.log 'Usage: fo -c <commitType> <commitMessage> [<bugId>]'
          console.log 'Options:'
          console.log '  --help, -h       Show this help message'
          console.log '  --version, -V    Show version information'
          console.log '  --verbose, -v    Enable verbose output'
          console.log '  --no-close, -N   Do not close the process after execution'
          return
        when '--version', '-V'
          console.log "Formal-Git version v#{version}"
          return
        when '--verbose', '-v'
          verbose = true
        when '--no-close', '-N'
          noClose = true
        else
          if arg.startsWith '--'
            console.log "Unknown option: #{arg}"
            return
          else
            extraArgs.push arg
  try
    commitType = extraArgs[0]
    commitMessage = extraArgs[1]
    if commitType == undefined or commitMessage == undefined
      console.log "Usage: fo -c <commitType> <commitMessage> [<bugId>]"
      return
    if extraArgs.length > 2
      bugId = extraArgs[2]
  catch error
    console.log "Invalid arguments: #{error.message}"
    return

  commitType = getCorrectCommitType commitType
  if verbose
    console.log "Commit Type: #{commitType}"
    console.log "Commit Message: #{commitMessage}"
    if bugId
      console.log "Bug ID: #{bugId}"
    else
      console.log "No Bug ID provided"

  template = getCommitTemplate


main removeBinFromArgs process.argv