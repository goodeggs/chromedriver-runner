path = require 'path'
fs = require 'fs'
{spawn} = require 'child_process'
request = require 'request'
async = require 'async'

class Chromedriver

  constructor: ({@port, @logfile}={}) ->
    @port ?= 9515
    @logfile ?= path.join process.cwd(), 'chromedriver.log'
    @url = "http://localhost:#{@port}"

  # swallows errors
  _isRunning: (cb) ->
    request.get "http://localhost:#{@port}/status", json: true, timeout: 500, (err, res) ->
      cb null, res?.statusCode is 200

  start: (opts={}, cb) ->
    [opts, cb] = [{}, opts] if !cb? and typeof opts is 'function'

    @_log = fs.createWriteStream @logfile, flags: 'a'
    @_isRunning (err, running) =>
      if running
        @_log.write 'already running\n'
        return cb()

      @_spawn()

      # wait for chromedriver to come up
      async.retry 10, (done) =>
        @_isRunning (err, running) =>
          return done() if running
          setTimeout ->
            done new Error('chromedriver failed to start after 10 seconds')
          , 500
      , cb

  _spawn: ->
    @_process = spawn 'chromedriver', ["--port=#{@port}"], stdio: 'pipe'
    process.on 'exit', @_process.kill.bind(@_process) # in case we die suddenly
    @_process.stdout.pipe(@_log)
    @_process.stderr.pipe(@_log)

  stop: ->
    @_process?.kill()
    @_log.close()

Chromedriver.create = (opts) ->
  new Chromedriver opts

module.exports = Chromedriver

