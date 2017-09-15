require 'rails_helper'

describe SlackController do
  describe 'GET command' do
    before do
      expect(ENV).to receive(:[]).with('APP_HOST').and_return('comakery.museum')
    end
    it 'responds with welcome text' do
      post :command
      expect(response.body).to match /helps you share revenue/
      expect(response.body).to match /comakery.museum/
    end
  end
end

# When Slack sends us a slash command, they POST params like:
# {
#   "token"=>"XXXXXXXXXXXXXXXXXXXXX",
#   "team_id"=>"T0XXXXXXX",
#   "team_domain"=>"swarmbot",
#   "channel_id"=>"C0XXXXXXX",
#   "channel_name"=>"bot-testing",
#   "user_id"=>"U0XXXXXXX",
#   "user_name"=>"joe",
#   "command"=>"/swarmbot",
#   "text"=>"help",
#   "response_url"=>"https://hooks.slack.com/commands/T0XXXXXXX/XXXXXXX/XXXXXXXXXXXXXX"
# }
