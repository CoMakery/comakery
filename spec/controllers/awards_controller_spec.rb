require 'rails_helper'

describe AwardsController do
  let!(:team) { create :team }
  let!(:issuer) { create(:account, email: 'issuer@example.com') }
  let!(:receiver) { create(:account, email: 'receiver@example.com') }
  let!(:other_account) { create(:account, mail: 'other@example.com') }
  let!(:different_team_account) { create(:account, email: 'different@example.com') }

  let(:project) { create(:project, account: issuer, public: false, maximum_tokens: 100_000_000) }

  before do
    team.accounts << issuer
    team.accounts << receiver
    team.accounts << other_account
  end
  describe '#index' do
    let!(:award) { create(:award, award_type: create(:award_type, project: project), account: other_account) }
    let!(:different_project_award) { create(:award, award_type: create(:award_type, project: create(:project)), account: other_account) }

    context 'when logged in' do
      before { login(issuer) }

      it 'shows awards for current project' do
        get :index, params: { project_id: project.to_param }

        expect(response.status).to eq(200)
        expect(assigns[:project]).to eq(project)
        expect(assigns[:awards]).to match_array([award])
      end
    end

    context 'when logged out' do
      context 'with a public project' do
        let!(:public_project) { create(:project, account: issuer, public: true) }
        let!(:public_award) { create(:award, award_type: create(:award_type, project: public_project)) }

        it 'shows awards for public projects' do
          get :index, params: { project_id: public_project.to_param }

          expect(response.status).to eq(200)
          expect(assigns[:project]).to eq(public_project)
          expect(assigns[:awards]).to match_array([public_award])
        end
      end

      context 'with a private project' do
        let!(:private_project) { create(:project, account: issuer, public: false) }
        let!(:private_award) { create(:award, award_type: create(:award_type, project: private_project)) }

        it 'sends you away' do
          get :index, params: { project_id: private_project.to_param }

          expect(response.status).to eq(302)
          expect(response).to redirect_to('/404.html')
        end
      end
    end

    describe 'checks policy' do
      before do
        allow(controller).to receive(:policy_scope).and_call_original
        allow(controller).to receive(:authorize).and_call_original
      end

      specify do
        login issuer

        get :index, params: { project_id: project.id }
        expect(controller).to have_received(:authorize).with(controller.instance_variable_get('@project'), :show_contributions?)
      end

      specify do
        project.update_attributes(public: true)

        get :index, params: { project_id: project.id }
        expect(controller).to have_received(:authorize).with(controller.instance_variable_get('@project'), :show_contributions?)
      end
    end
  end

  describe '#create' do
    let(:award_type) { create(:award_type, project: project) }

    before do
      login(issuer)
      request.env['HTTP_REFERER'] = "/projects/#{project.to_param}"
    end

    context 'logged in' do
      it 'records a award being created' do
        expect_any_instance_of(Account).to receive(:send_award_notifications)
        allow_any_instance_of(Award).to receive(:ethereum_issue_ready?) { true }

        expect do
          post :create, params: {
            project_id: project.to_param, award: {
              slack_user_id: receiver_authentication.slack_user_id,
              award_type_id: award_type.to_param,
              quantity: 1.5,
              description: 'This rocks!!11'
            }
          }
          expect(response.status).to eq(302)
        end.to change { project.awards.count }.by(1)

        expect(response).to redirect_to(project_path(project))
        expect(flash[:notice]).to eq('Successfully sent award to Rece Iver')

        award = Award.last
        expect(award.award_type).to eq(award_type)
        expect(award.authentication).to eq(receiver_authentication)
        expect(award.issuer).to eq(issuer)
        expect(award.description).to eq('This rocks!!11')
        expect(award.quantity).to eq(1.5)
        expect(EthereumTokenIssueJob.jobs.first['args']).to eq([award.id])
      end

      it "renders error if you specify a award type that doesn't belong to a project" do
        expect_any_instance_of(Account).not_to receive(:send_award_notifications)
        expect do
          post :create, params: {
            project_id: project.to_param, award: {
              slack_user_id: 'receiver id',
              award_type_id: create(:award_type, amount: 10000, project: create(:project, slack_team_id: 'hackerz', maximum_tokens: 100_000)).to_param,
              description: 'I am teh haxor'
            }
          }
          expect(response.status).to eq(302)
        end.not_to change { project.awards.count }
        expect(flash[:error]).to eq('Failed sending award - Not authorized')
      end

      it "renders error if you specify a slack user id that doesn't belong to a project" do
        expect_any_instance_of(Account).not_to receive(:send_award_notifications)
        expect do
          post :create, params: {
            project_id: project.to_param, award: {
              slack_user_id: 'different team member id',
              award_type_id: award_type.to_param,
              description: 'I am teh haxor'
            }
          }
          expect(response.status).to eq(302)
        end.not_to change { project.awards.count }
        expect(flash[:error]).to eq('Failed sending award - Not authorized')
      end

      it 'redirects back to projects show if error saving' do
        expect do
          post :create, params: {
            project_id: project.to_param, award: {
              slack_user_id: receiver_authentication.slack_user_id,
              description: 'This rocks!!11'
            }
          }
          expect(response.status).to eq(302)
        end.not_to change { project.awards.count }

        expect(response).to redirect_to(project_path(project))
        expect(flash[:error]).to eq('Failed sending award - missing award type')
      end
    end
  end
end
