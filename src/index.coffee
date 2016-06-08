_               = require 'lodash'
{EventEmitter}  = require 'events'
TwitterStream   = require './twitter-stream.coffee'
debug           = require('debug')('meshblu-connector-twitter-stream:index')

class TwitterStreamConnector extends EventEmitter
  constructor: ->
    @COMMANDS =
      start: 'startStreaming'
      stop:  'stopStreaming'
    @emitTweet = _.throttle @_emitTweet, 100, { leading: true }

  isOnline: (callback) =>
    callback null, { running: !!@twitterStream }

  close: (callback) =>
    @stopStreaming()
    callback()

  onMessage: ({ payload }={}) =>
    { command } = payload ? {}
    return @emitError('invalid command') unless command?
    action = @COMMANDS[command]
    return @emitError('invalid action') unless action?
    debug 'running command', command
    @[action]()

  onConfig: ({ options, credentials }={}) =>
    options ?= {}
    @searchQuery = options.searchQuery
    @credentials = _.mapValues credentials, (value) =>
      return value.trim()
    debug 'set options', { @searchQuery, @credentials }

  start: (device) =>
    @onConfig device

  _emitTweet: (tweet={}) =>
    debug 'emitting tweet', tweet.id_str
    data =
      devices: ['*']
      topic: 'tweet'
      tweet: tweet
    @emit 'message', data

  emitError: (error) =>
    debug 'error', error
    data =
      devices: ['*']
      topic: 'error'
      error: error
    @emit 'message', data

  startStreaming: =>
    return @emitError('Missing searchQuery') unless @searchQuery
    debug 'starting twitter streamer'
    @twitterStream = new TwitterStream @credentials
    @twitterStream.start @searchQuery, @emitTweet, @emitError

  stopStreaming: =>
    debug 'stopping stream'
    return unless @twitterStream?
    @twitterStream.stop()
    @twitterStream = null

module.exports = TwitterStreamConnector
