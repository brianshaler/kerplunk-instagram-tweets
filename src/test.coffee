Promise = require 'when'

tweet1 =
  guid: '_test-tweet1'
  platform: 'twitter'
  message: 'no checkin'

tweet2 =
  guid: '_test-tweet2'
  platform: 'twitter'
  message: 'blah https://foursquare.com/wat/checkin/foursquare-id blah'

checkin1 =
  guid: '_test-checkin1'
  platform: 'foursquare'
  data:
    id: 'other-id'

checkin2 =
  guid: '_test-checkin2'
  platform: 'foursquare'
  data:
    id: 'foursquare-id'

module.exports = (System) ->
  ->
    mongoose = System.getMongoose 'public'
    ActivityItem = mongoose.model 'ActivityItem'

    mpromise = ActivityItem
    .where
      guid: /^_test/
    .remove()
    Promise(mpromise).then ->
      item1 = new ActivityItem checkin2
      System.do 'activityItem.save', item1
    .then ->
      item2 = new ActivityItem tweet2
      System.do 'activityItem.save', item2
