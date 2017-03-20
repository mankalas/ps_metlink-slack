require "metlink_slackbot/version"
require "slack-ruby-bot"
require "nokogiri"
require "open-uri"
require "eventmachine"



class MetlinkBot < SlackRubyBot::Bot
  Struct.new("Bus", :line, :destination)
  Struct.new("BusArrival", :bus, :eta)

  help do
    title "Metlink Bot"
    desc "Never miss your bus again! Well, at least, you will have one fewer excuse with this bot.\n\n"\
         "IMPORTANT: For now, this bot onyl accepts bus stop ids. These are the ids for the bus stops closest to Hanson St.\n"\
         "\tAdelaide Road at Hospital Road is 6016\n"\
         "\tJohn St. at Adelaide Road is 6918\n"\
         "\tWellington Hospital is 7017\n"

    command 'info' do
      desc "Gets you info about the incoming buses at a particular bus station."
    end
  end

  def run
    @@stops_expectations = {}
    super
  end

  def self.time_of_arrival(eta)
    if eta == "Due"
      Time.now + 60
    elsif m = eta.match(/(\d+) mins/)
      minutes = m.captures
      Time.now + minutes * 60
    elsif m = eta.match(/(\d+):(\d+)([ap])m/)
      hours, minutes, ap = m.captures
      Time.new(Time.now.year, Time.now.month, Time.now.day, hours.to_i + (ap == "a" ? 0 : 12), minutes.to_i)
    end
  end

  def self.arrivals(stop_id)
    page = Nokogiri::HTML(open("https://www.metlink.org.nz/realtime-display/#{stop_id}"))
    page.css('tr').collect do |row|
      line = row.css('span.id').text.strip
      destination = row.css('td.destination span').text.strip
      eta = row.css('td.time span').text.strip
      BusArrival(:bus => Bus.new(:line => line,
                                 :destination => destination),
                 :eta => time_of_arrival(eta))
    end
  end

  def self.check
    pages = {}

    @@waitboard.each_key do |stop|
      arrivals(stop).collect do |arrival|

      end
    end
  end

  command 'info' do |client, data, match|
    arrivals(match[:expression]).collect do |arrival|
      result = "Bus #{arrival.line} to #{arrival.destination} should arrive at #{arrival.eta}."
      client.say(:text => result, :channel => data.channel)
    end
  end


  notify_regex = /^Notify me (?<delay>\d+) minutes when bus (?<line>\w+) to (?<destination>\w+) arrives at <?(stop_id>\d{4}>$)/
  match notify_regex do |client, data, match|
    user = data[:user]
    stop = match[:stop_id]
    delay = match[:delay].to_i

    bus = Struct::Bus.new(:line => match[:line],
                          :destination => match[:destination])

    bus_hash[bus]

    # Add bus to stop
    @@waitboard[stop] = [] if !@@waitboard.has_key?(stop)
    @@waitboard[stop] << {:bus => bus, :delay => delay } if !@@waitboard[stop].include?(bus)

    # Add the delay per user
    @@waitboard[stop]

    EventMachine.add_periodic_timer(1) { check }

    result = "Ok <@user>, I'll warn you #{match[:delay]} minutes before bus #{match[:line]} arrives at #{match[:stop_id]}"
    client.say(:text => result, :channel => "<@SlackBot>")
  end

  command "hello" do |client, data, match|
    client.say(:text => "/remind <@data.user> prout in 2 seconds", :channel => data.channel)
  end
end

class Expectation
  attr_reader :user, :delay

  def initialize(user, delay)
    @user = user
    @delay = delay
  end
end

class BusExpectations
  attr_reader :bus, :expectations

  def initialize(bus)
    @bus = bus
    @expectations = {}
  end
end

class StopExpectation
  attr_reader :bus_expectations

  def initialize(stop)
    @stop = stop
    @bus_expectations = {}
  end

  def add(bus, user, delay)
    if bus_expectations.include?(bus)
      bus_expectations[bus] << Expectation.new(user, delay)
    else

    end
  end
end
