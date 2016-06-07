{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-twitter-stream:index')
_               = require 'lodash'
TwitterStream   = require './twitter-stream.coffee'
TwitterRequest  = require './twitter-request.coffee'

class TwitterStreamConnector extends EventEmitter
  constructor: ->
    @COMMANDS =
      start: 'startStreaming'
      stop:  'stopStreaming'
      get:   'getRequest'
      post:  'postRequest'
    debug 'TwitterStream constructed'

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onMessage: (message) =>
    return unless message.payload?
    { request, command } = message.payload
    action = @COMMANDS[command]
    return unless action?
    debug 'running command', command
    @[action](request)

  onConfig: (device) =>
    @options = _.mapValues device.options, (value) =>
      return value.trim()
    debug 'set options', @options

  start: (device) =>
    { @uuid } = device
    debug 'started', @uuid

  emitTweet: (tweet={}) =>
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
    @emit 'error', data

  startStreaming: =>
    debug 'starting twitter streamer'
    twitterCreds =
      consumer_key: @options.consumerKey
      consumer_secret: @options.consumerSecret
      access_token_key: @options.accessTokenKey
      access_token_secret: @options.accessTokenSecret
    @twitterStream = new TwitterStream twitterCreds
    throttleTweet = _.throttle @emitTweet, 100
    @twitterStream.start @options.searchQuery, throttleTweet, @emitError

  stopStreaming: =>
    debug 'stopping stream'
    return unless @twitterStream?
    @twitterStream.stop()
    @twitterStream = null

  postRequest: (request={}) ->
    return @emitError 'Missing endpoints' unless request.endpoints?
    return @emitError 'Missing params' unless request.params?
    debug 'posting request'
    @twitterReq = new TwitterRequest @options unless @twitterReq?
    @twitterReq.post request, (error, tweet) =>
      return @emitError(error?.message ? error) if error?
      debug 'response is', tweet
      @emitTweet tweet

  getRequest: (request={}) =>
    debug 'geting request'
    return @emitError 'Missing endpoints' unless request.endpoints?
    return @emitError 'Missing params' unless request.params?
    @twitterReq = new TwitterRequest @options unless @twitterReq?
    @twitterReq.get request, (error, tweet) =>
      return @emitError(error?.message ? error) if error?
      debug 'response is', tweet
      @emitTweet tweet

module.exports = TwitterStreamConnector
