Twitter = require 'twitter'
_       = require 'lodash'
debug   = require('debug')('meshblu-twitter-stream:twitter-request')

class TwitterRequest
  constructor: (@options={}) ->
    @credentials =
      consumer_key: @options.consumerKey
      consumer_secret: @options.consumerSecret
      access_token_key: @options.accessTokenKey
      access_token_secret: @options.accessTokenSecret

    debug 'twitter Creds for post', @credentials
    @client ?= new Twitter @credentials

  post: (request, callback) =>
    @client.post request.endpoints, request.params, (error, tweet, response) =>
      callback error, tweet

  get: (request, callback) =>
    @client.get request.endpoints, request.params, (error, tweet, response) =>
      callback error, tweet

module.exports = TwitterRequest
