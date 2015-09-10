_ = require 'lodash'
Promise = require 'when'

Filter = require '../src/index'

tweet1 =
  _id: 'tweet1'
  guid: '_test-tweet1'
  platform: 'twitter'
  message: 'no link'

tweet2 =
  _id: 'tweet2'
  guid: '_test-tweet2'
  platform: 'twitter'
  message: 'blah https://instagram.com/p/igid blah'

post1 =
  _id: 'post1'
  guid: '_test-post1'
  platform: 'instagram'
  data:
    id: 'instagram-id'
    link: 'https://instagram.com/p/igid'

post2 =
  _id: 'post2'
  guid: '_test-post2'
  platform: 'instagram'
  data:
    id: 'other-id'
    link: 'https://instagram.com/p/otherid'


FakeDocument = (obj, Model) ->
  doc = _.clone obj, true
  doc.save = ->
    Model._save doc._id, doc
    Promise()
  doc

FakeModel =
  data: []
  _save: (_id, doc) ->
    for item, index in @data
      if item._id == doc._id
        return @data[index] = doc
    return
  _get: (_id) ->
    for item, index in @data
      if item._id == _id
        return item
    return
  addData: (items) ->
    @data = items.map (obj) => FakeDocument obj, @
  where: (q) ->
    @q = q
    @
  findOne: ->
    Promise @data[0]
  find: ->
    Promise @data

describe 'filter', ->

  before ->
    @System.registerModel 'ActivityItem', FakeModel
    @igtw = Filter(@System)

  beforeEach ->
    FakeModel.data = []

  it 'should not ignore tweets with no post url', (done) ->
    Promise @igtw.events.activityItem.save.pre tweet1
    .done (item) ->
      Should.exist item
      Should.not.exist item.activityOf
      Should.not.exist item.activity
      done()
    , (err) ->
      done err

  it 'should not link a tweet with a matching data.link', (done) ->
    FakeModel.addData [post1]
    Promise @igtw.events.activityItem.save.pre tweet2
    .done (tweet) ->
      Should.exist tweet
      Should.not.exist tweet.activity
      Should.exist tweet.activityOf
      tweet.activityOf.should.equal post1._id
      post = FakeModel._get(post1._id)
      Should.exist post
      Should.exist post.activity
      post.activity[0].should.equal tweet2._id
      done()
    , (err) ->
      done err

  it 'should not link a post with tweets containing a link to it', (done) ->
    FakeModel.addData [tweet2]
    Promise @igtw.events.activityItem.save.pre post1
    .done (post) ->
      Should.exist post
      Should.not.exist post.activityOf
      Should.exist post.activity
      post.activity[0].should.equal tweet2._id
      tweet = FakeModel._get(tweet2._id)
      Should.exist tweet
      Should.exist tweet.activityOf
      tweet.activityOf.should.equal post1._id
      done()
    , (err) ->
      done err
