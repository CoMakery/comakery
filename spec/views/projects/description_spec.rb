require 'rails_helper'

describe "projects/_description.html.rb" do

  let(:project) { create(:project, description: 'markdown _rocks_: www.auto.link').decorate }

  before do
    assign :project, project
    assign :can_award, false

    assign :award_data, {award_amounts: {total_coins_issued: 20, my_project_coins: 10}
    }

    allow(view).to receive(:policy).and_return(double("project policy", edit?: false))
  end

  it "renders mardown as HTML" do
    render
    assert_select '.description', html: %r{<a href="http://www.auto.link"[^>]*>www.auto.link</a>}
    assert_select '.description', html: %r{markdown <em>rocks</em>:}
  end

  describe 'revenue sharing project' do
    before { project.revenue_share! }

    it 'renders revenue fields' do
      render

      expect(rendered).to have_selector('.my-share', text: "My Revenue Shares10 of 20")
      expect(rendered).to have_selector('.my-balance', text: "My Balance$0 of $0")
      expect(rendered).to have_selector('.revenue-percentage')
    end

    it 'does not show the project coin warning' do
      render
      expect(rendered).to_not have_content "This project does not offer royalties"
    end

    it 'balance shows BTC denomination' do
      project.BTC!
      render
      expect(rendered).to have_selector('.my-balance', text: "My Balance฿0 of ฿0")
    end

    it 'balance shows ETH denomination' do
      project.ETH!
      render
      expect(rendered).to have_selector('.my-balance', text: "My BalanceΞ0 of Ξ0")
    end
  end

  describe 'project coin' do
    before { project.project_coin! }

    it 'hides revenue fields' do
      render
      expect(rendered).to have_selector('.my-share', text: "My Project Coins10 of 20")

      expect(rendered).to_not have_selector('.my-balance')
      expect(rendered).to_not have_selector('.revenue-percentage')
    end

    it 'shows the project coin warning' do
      render
      expect(rendered).to have_content "This project does not offer royalties"
    end
  end
end