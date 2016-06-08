# Description:
#   What is ZeroCater catering us today?
#
# Dependencies:
#   "cheerio": "0.12.x"
#   "moment": "2.0.x"
#
# Configuration:
#   HUBOT_ZEROCATER_MENU_URL - In the format of https://zerocater.com/m/xxxx
#   HUBOT_ZEROCATER_CATERING_TIME - In the format of HH:MM
#
# Commands:
#   hubot zerocater - Pulls your catering menu for today
#   hubot zerocater yesterday - Yesterday's catering menu
#   hubot zerocater tomorrow - Tomorrow's catering menu
#
# Author:
#   jonursenbach

moment = require 'moment'
cheerio = require 'cheerio'

module.exports = (robot) =>
  robot.respond /zerocater( .*)?/i, (msg) ->
    date = if msg.match[1] then msg.match[1].trim() else ''
    if date isnt undefined && date != ''
      date = getTimestamp(date)
      if date is false
        getLunch msg, false
      else
        getLunch msg, date
    else
      getLunch msg, moment()

getTimestamp = (date) ->
  if !isNaN(new Date(date).getTime())
    return moment(date)

  if /(yesterday|today|tomorrow)/i.test(date)
    switch date
      when 'yesterday'
        return moment().subtract('d', 1)
      when 'today'
        return moment()
      when 'tomorrow'
        return moment().add('d', 1)
  else
    return false

# getCatering = (msg, date) ->
#   if date is false
#     return msg.send 'I don\'t know when that is.'

#   msg.http(process.env.HUBOT_ZEROCATER_MENU_URL)
#     .get() (err, res, body) ->
#       return msg.send "Sorry, Zero Cater doesn't like you. ERROR:#{err}" if err
#       return msg.send "Unable to get a catering menu: #{res.statusCode + ':\n' + body}" if res.statusCode != 200

#       $ = cheerio.load(body)

#       cateringFound = false;
#       searchDate = date.format('YYYY-MM-DD');

#       $('div.menu[data-date="' + searchDate + '"]').each (i, elem) ->
#         if (cateringFound)
#           return

#         menu = $(this)
#         header = menu.find('.meal-header')
#         time = menu.find('.header-time').text().split('\n').filter (i, elem) ->
#           return !!i.trim();

#         deliveryTime = time[1].trim()

#         # It seems that ZeroCater sometimes only has one delivery on some days,
#         # so if there's only one entry for this date, we can ignore trying to
#         # match against the specified catering time.
#         if $('div.menu[data-date="' + searchDate + '"]').length > 1
#           if deliveryTime.match(process.env.HUBOT_ZEROCATER_CATERING_TIME, 'g') == null
#             return

#         cateringFound = true

#         emit = 'Catering for ' + searchDate + ' at ' + deliveryTime + ' is coming from ' + header.find('.vendor').text().trim().split('\n')[0] + '.\n\n'
#         menu.find('.list-group-item').each (i, elem) ->
#           item = $(this).find('.item-name').text().trim().replace(/(\r\n|\n|\r)/gm,"")
#           description = $(this).find('.item-description').text().trim().replace(/(\r\n|\n|\r)/gm,"")
#           instructions = $(this).find('.item-instructions').text().trim().replace(/(\r\n|\n|\r)/gm,"")

#           emit += item + '\n'
#           if (description != '')
#             emit += ' - ' + description + '\n'

#           if (instructions != '')
#             emit += ' - Note: ' + instructions + '\n'

#         msg.send emit

#       if (!cateringFound)
#         msg.send "Sorry, I was unable to find a menu for #{searchDate}."

getLunch = (msg, date) ->
  # day = if !msg.match[1] then 'today' else msg.match[1].trim().toLowerCase()
  # now =  Math.floor(new Date().getTime() / 1000)
  # now = now + 43200 if day == 'tomorrow'
  
  url = "https://api.zerocater.com/v3/companies/#{process.env.ZEROCATER_TAG}/meals"
  msg.http(url).get() (err, res, body) ->
    meals = JSON.parse(body)
    themeal = (m for m in meals when m.time > date - 14400)[0]
    details = "https://zerocater.com/m/#{process.env.ZEROCATER_TAG}/#{themeal.id}"
    msg.http("#{themeal.url}").get() (err, res, meal) ->
      m = JSON.parse(meal)
      choices = (item.name for item in m.items).join(', ')
      img = m.vendor_image_url.replace /upload/, "upload/c_fill,h_250,w_400"
      msg.send "Lunch #{day}: #{m.name} (from #{m.vendor_name})\n#{choices}\nDetails: #{details}\n#{img}"
