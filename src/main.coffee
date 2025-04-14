
{spawn, exec}  = require 'child_process'
process = require 'process'
{version} = require '../package.json'
fs = require 'fs'
url = require 'url'

SWITCHES = [
  '--help'
  '--version'
  '--verbose'
  '--no-close'
  '--no-add'
  '-N' # no-close
  '-v' # verbose
  '-h' # help
  '-V' # version
  '-A' # no-add
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
    'fe': 'feat'
    'f': 'fix'
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
    return "{type}({components}): {bugId} - {message}"

getChangedFiles = (callback) ->
  # Get the list of changed files
  changedFiles = []
  exec 'git diff --cached --name-only', (error, stdout, stderr) ->
    if error
      console.error "Error getting changed files: #{error.message}"
      return
    changedFiles = stdout.split('\n').filter (file) -> file.length > 0
    callback changedFiles

stageFilesToCommit = (callback) ->
  exec 'git add .', (error, stdout, stderr) ->
    if error
      console.error "Error staging files: #{error.message}"
      return
    console.log "Files staged for commit"
    callback()

getDefinedComponents = ->
  # Get the list of components from a .formal-git file
  componentsFile = '.formal-git-components'
  if fs.existsSync componentsFile
    components = fs.readFileSync componentsFile, 'utf8'
    return components.split('\n').filter (component) -> component.length > 0
  else
    return []

getProperBugId = (bugId) ->
  if bugId == undefined or bugId == ''
    return undefined

  checkBugId = (bugId) ->
    # Check if the bug ID is a number
    if /^[0-9]+$/.test(bugId)
      return true
    else
      throw new Error "Invalid bug ID: #{bugId}"

  # If it's a github link, get the last part of the link
  # If it starts with a #, remove it
  # Otherwise, just return the number (and check if it's a number)
  if bugId.startsWith('http')
    if bugId.endsWith('/')
      bugId = bugId.slice(0, -1)
    bugId = url.parse(bugId).pathname.split('/').pop()
  else if bugId.startsWith('#')
    bugId = bugId.slice(1)
  return checkBugId bugId

main = (args) ->
  args = args
  commitType = ""
  commitMessage = ""
  bugId = ""
  verbose = false
  noClose = false
  extraArgs = []
  dontAdd = false
  for arg in args
    if arg in SWITCHES
      switch arg
        when '--help'
          console.log 'Usage: fo <commitType> <commitMessage> [<bugId>]'
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
        when '--no-add', '-A'
          dontAdd = true
    else
      if arg.startsWith '-'
        console.log "Unknown option: #{arg}"
        return
      else
        extraArgs.push arg

  try
    commitType = extraArgs[0]
    commitMessage = extraArgs[1]
    if commitType == undefined or commitMessage == undefined
      console.log "Usage: fo <commitType> <commitMessage> [<bugId>]"
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

  bugId = getProperBugId bugId
  bugIdMessage = ""
  if bugId
    if not noClose
      bugIdMessage = "closes ##{bugId}"
    else
      bugIdMessage = "bug ##{bugId}"
  else
    bugIdMessage = "no-bug"  

  stageFilesCallback = () -> 
    getChangedFiles (changedFiles) ->
      definedComponents = getDefinedComponents()
      usedComponents = []
      for file in changedFiles
        for component in definedComponents
          if file.includes component
            usedComponents.push component
      components = usedComponents.join(', ')
      if usedComponents.length == 0
        components = 'no-component'


      if changedFiles.length == 0
        console.log "No files to commit"
        return

      template = getCommitTemplate()
      message = template
        .replace('{type}', commitType)
        .replace('{components}', components)
        .replace('{bugId}', bugIdMessage)
        .replace('{message}', commitMessage)
      if verbose
        console.log "Commit message: #{message}"
      exec "git commit -m '#{message}'", (error, stdout, stderr) ->
        if error
          console.error "Error committing: #{error.message}"
          return
        if verbose
          console.log "Commit output: #{stdout}"
        if not noClose
          process.exit(0)
        else
          console.log "Commit successful, but not closing the process"
          return
      if not noClose
        process.exit(0)
      else
        console.log "Process not closed as per --no-close option"

  if not dontAdd
    stageFilesToCommit stageFilesCallback
  else
    stageFilesCallback()

try
  main removeBinFromArgs process.argv
catch error
  console.error "Error: #{error.message}"
  process.exit(1)
