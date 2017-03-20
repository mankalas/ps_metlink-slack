require 'spec_helper'
require 'slack-ruby-bot/rspec'


describe MetlinkSlackbot do
  it 'has a version number' do
    expect(MetlinkSlackbot::VERSION).not_to be nil
  end

  it 'says hi' do
    expect(message: "#{SlackRubyBot.config.user} hi").to respond_with_slack_message('Hi <@user>!')
  end

  it "#info" do
    expect(MetlinkBot).to receive(:metlink_page).and_return(Nokogiri::HTML('<tr><span class="id">1</span><td class="destination"><span>The Yellow Brick Road</span><td class="time"><span>12 minutes</span></tr>'))
    expect(message: "#{SlackRubyBot.config.user} info 1").to respond_with_slack_message("Bus 1 to The Yellow Brick Road should arrive in 12 minutes.")
  end

end
