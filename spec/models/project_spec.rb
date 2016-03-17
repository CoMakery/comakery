require 'rails_helper'

describe Project do
  describe 'validations' do
    it 'requires an owner' do
      expect(Project.new.tap(&:valid?).errors.full_messages.sort).to eq(["Owner account can't be blank",
                                                                         "Slack channel can't be blank",
                                                                         "Slack team can't be blank",
                                                                         "Slack team image 132 url can't be blank",
                                                                         "Slack team image 34 url can't be blank",
                                                                         "Slack team name can't be blank",
                                                                         "Title can't be blank",
                                                                        ])

      expect(Project.new(slack_team_domain: "").tap{|p|p.valid?}.errors.full_messages).to be_include("Slack team domain can't be blank")
      expect(Project.new(slack_team_domain: "XX").tap{|p|p.valid?}.errors.full_messages).to be_include("Slack team domain must only contain lower-case letters, numbers, and hyphens and start with a letter or number")
      expect(Project.new(slack_team_domain: "-xx").tap{|p|p.valid?}.errors.full_messages).to be_include("Slack team domain must only contain lower-case letters, numbers, and hyphens and start with a letter or number")
      expect(Project.new(slack_team_domain: "good\n-bad").tap{|p|p.valid?}.errors.full_messages).to be_include("Slack team domain must only contain lower-case letters, numbers, and hyphens and start with a letter or number")

      expect(Project.new(slack_team_domain: "3-xx").tap{|p|p.valid?}.errors.full_messages).not_to be_include("Slack team domain must only contain lower-case letters, numbers, and hyphens and start with a letter or number")
      expect(Project.new(slack_team_domain: "a").tap{|p|p.valid?}.errors.full_messages).not_to be_include("Slack team domain must only contain lower-case letters, numbers, and hyphens and start with a letter or number")
    end

    describe "tracker" do
      it "is valid if tracker is a valid, absolute url" do
        project = Project.create!(owner_account: create(:account), title: "title", slack_team_id: "bar", slack_channel: "slack_channel", slack_team_name: "baz", slack_team_image_34_url: "happy-34.gif", slack_team_image_132_url: "happy-132.gif", tracker: "http://foo.com")
        expect(project).to be_valid
        expect(project.tracker).to eq("http://foo.com")
      end

      it "requires the tracker url be valid if present" do
        project = Project.new(owner_account: create(:account), title: "title", slack_team_id: "bar", slack_channel: "slack_channel", slack_team_name: "baz", slack_team_image_34_url: "happy-34.gif", slack_team_image_132_url: "happy-132.gif", tracker: "foo")
        expect(project).not_to be_valid
        expect(project.errors.full_messages).to eq(["Tracker must be a valid url"])
      end

      it "is valid with no tracker specified" do
        project = Project.new(owner_account: create(:account), title: "title", slack_team_id: "bar", slack_channel: "slack_channel", slack_team_name: "baz", slack_team_image_34_url: "happy-34.gif", slack_team_image_132_url: "happy-132.gif", tracker: nil)
        expect(project).to be_valid
      end

      it "is valid if tracker is blank" do
        project = Project.create!(owner_account: create(:account), title: "title", slack_team_id: "bar", slack_channel: "slack_channel", slack_team_name: "baz", slack_team_image_34_url: "happy-34.gif", slack_team_image_132_url: "happy-132.gif", tracker: "")
        expect(project.tracker).to be_nil
      end
    end
  end

  describe 'associations' do
    it 'has many award_types and accepts them as nested attributes' do
      project = Project.create!(
          title: 'This is a title',
          owner_account: create(:account),
          slack_team_id: '123',
          slack_channel: "slack_channel",
          slack_team_name: 'This is a slack team name',
          slack_team_image_34_url: 'http://foo.com/kittens-34.jpg',
          slack_team_image_132_url: 'http://foo.com/kittens-132.jpg',
          award_types_attributes: [
              {'name' => 'Small award', 'amount' => '1000'},
              {'name' => '', 'amount' => '1000'},
              {'name' => 'Award', 'amount' => ''}
          ])

      expect(project.award_types.count).to eq(1)
      expect(project.award_types.first.name).to eq('Small award')
      expect(project.award_types.first.amount).to eq(1000)
      expect(project.slack_team_id).to eq('123')
      expect(project.slack_team_name).to eq('This is a slack team name')
      expect(project.slack_team_image_34_url).to eq('http://foo.com/kittens-34.jpg')
      expect(project.slack_team_image_132_url).to eq('http://foo.com/kittens-132.jpg')

      project.update(award_types_attributes: {id: project.award_types.first.id, _destroy: true})
      expect(project.award_types.count).to eq(0)
    end
  end

  describe 'scopes' do
    describe ".with_last_activity_at" do
      it "returns projects ordered by when the most recent award created_at, then by project created_at" do
        p1_8 = create(:project, title: "p1_8", created_at: 8.days.ago).tap{|p| create(:award_type, project: p).tap{|at| create(:award, award_type: at, created_at: 1.days.ago)}}
        p2_3 = create(:project, title: "p2_3", created_at: 3.days.ago).tap{|p| create(:award_type, project: p).tap{|at| create(:award, award_type: at, created_at: 2.days.ago)}}
        p3_6 = create(:project, title: "p3_6", created_at: 6.days.ago).tap{|p| create(:award_type, project: p).tap{|at| create(:award, award_type: at, created_at: 3.days.ago)}}
        p3_5 = create(:project, title: "p3_5", created_at: 5.days.ago).tap{|p| create(:award_type, project: p).tap{|at| create(:award, award_type: at, created_at: 3.days.ago)}}
        p3_4 = create(:project, title: "p3_4", created_at: 4.days.ago).tap{|p| create(:award_type, project: p).tap{|at| create(:award, award_type: at, created_at: 3.days.ago)}}

        expect(Project.count).to eq(5)
        expect(Project.with_last_activity_at.all.map(&:title)).to eq(%w(p1_8 p2_3 p3_4 p3_5 p3_6))
      end
    end

    describe "#community_award_types" do
      it "returns all award types with community_awardable? == true" do
        project = create(:project)
        community_award_type = create(:award_type, project: project, community_awardable: true)
        normal_award_type = create(:award_type, project: project, community_awardable: false)

        expect(project.community_award_types).to eq([community_award_type])
      end
    end
  end

  describe "#owner_slack_user_name" do
    let!(:owner) { create :account }
    let!(:project) { create :project, owner_account: owner, slack_team_id: 'reds' }

    it "returns the user name" do
      create(:authentication, account: owner, slack_team_id: 'reds', slack_first_name: "John", slack_last_name: "Doe", slack_user_name: 'johnny')
      expect(project.owner_slack_user_name).to eq('John Doe')
    end

    it "doesn't blow up if the isn't an auth" do
      expect(project.owner_slack_user_name).to be_nil
    end
  end
end
