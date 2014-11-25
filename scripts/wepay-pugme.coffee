# Description:
#   Pugme is the most important thing in life
#
# Dependencies:
# "cheerio: "0.7.0"
#
# Configuration:
#   None
#
# Commands:
#   hubot pug me - Receive a pug
#   hubot pug bomb N - get N pugs

cheerio = require('cheerio')

module.exports = (robot) ->

  robot.respond /pug me/i, (msg) ->
    msg.http("http://pugme.herokuapp.com/random")
      .get() (err, res, body) ->
        msg.send JSON.parse(body).pug

  robot.respond /pug bomb( (\d+))?/i, (msg) ->
    count = msg.match[2] || 5

    ignoreUsers = process.env.HUBOT_IRC_IGNORE_USERS?.split(",") or []
    sender = msg.message.user.mention_name

    if sender in ignoreUsers
      msg.send "@#{sender} I dont think that's a good idea"
    else if count > 50
      # reply = "@#{sender} http://38.media.tumblr.com/tumblr_m7l108S4z31rbd2hjo2_500.gif"
      # msg.send reply
      insult(msg, sender)
      # user.reply_to = user.jid if @robot.adapter is "hipchat"
      # robot.reply msg.message.user, 'test pm'
    else if count > 5
      msg.send "I think 5 is a better number than #{count}"
    else
      msg.http("http://pugme.herokuapp.com/bomb?count=" + count)
        .get() (err, res, body) ->
          msg.send pug for pug in JSON.parse(body).pugs

  robot.respond /how many pugs are there/i, (msg) ->
    msg.http("http://pugme.herokuapp.com/count")
      .get() (err, res, body) ->
        msg.send "There are #{JSON.parse(body).pug_count} pugs."


insult = (msg, name) ->
  msg
    .http("http://www.randominsults.net")
    .header("User-Agent: Insultbot for Hubot (+https://github.com/github/hubot-scripts)")
    .get() (err, res, body) ->
      msg.send "@#{name}: #{getQuote body}"

getQuote = (body) ->
  $ = cheerio.load(body)
  $('i').text()

