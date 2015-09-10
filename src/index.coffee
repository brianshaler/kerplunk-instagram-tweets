Promise = require 'when'

pattern = /\/\/instagram\.com\/p\/([a-z0-9\-_]+)\b/i

module.exports = (System) ->
  ActivityItem = System.getModel 'ActivityItem'

  preSave = (item) ->
    return item unless item.platform == 'twitter' or item.platform == 'instagram'
    deferred = Promise.defer()
    if item.platform == 'instagram' and item.data?.link?.length > 0
      mpromise = ActivityItem
      .where
        platform: 'twitter'
        message: new RegExp item.data.link
      .findOne()

      Promise mpromise
      .then (tweet) ->
        return item unless tweet
        tweet.activityOf = item._id
        Promise tweet.save()
        .then ->
          item.activity = [] unless item.activity?.length > 0
          item.activity.push tweet._id
          item
    else if pattern.test item.message
      match = item.message.match pattern
      mpromise = ActivityItem
      .where
        platform: 'instagram'
        'data.link': new RegExp match[1]
      .findOne()

      Promise mpromise
      .then (post) ->
        return item unless post
        post.activity = [] unless post.activity?.length > 0
        post.activity.push item._id
        Promise post.save()
        .then ->
          item.activityOf = post._id
          item
    else
      item

  events:
    activityItem:
      save:
        pre: preSave
