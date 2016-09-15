require "metlink_slackbot/version"
require "slack-ruby-bot"
require "nokogiri"
require "open-uri"

class MetlinkBot < SlackRubyBot::Bot
  command 'info' do |client, data, match|
    stop_id = match[:expression]

    page = Nokogiri::HTML(open("https://www.metlink.org.nz/realtime-display/#{stop_id}"))

    result = page.css('tr')[0..4].collect do |row|
      line = row.css('span.id').text.strip
      destination = row.css('td.destination span').text.strip
      eta = row.css('td.time span').text.strip
      result = "Bus #{line} to #{destination} should arrive in #{eta}."
      client.say(:text => result, :channel => data.channel)
    end
  end
end
