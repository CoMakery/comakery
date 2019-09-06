require 'rails_helper'

describe AwardType do
  describe 'associations' do
    let(:project) { create(:project, account: create(:account)) }

    let(:award_type) { create(:award_type, project: project) }
    let(:award) { create(:award, award_type: award_type) }

    it 'belongs to a project' do
      expect(award_type.project).to eq(project)
    end

    it 'has many awards' do
      expect(award_type.awards).to match_array([award])
    end
  end

  describe 'validations' do
    it 'requires many attributes' do
      award_type = described_class.new
      expect(award_type).not_to be_valid
      expect(award_type.errors.full_messages).to eq(["Project can't be blank"])
    end
  end

  describe 'switch_tasks_publicity' do
    let!(:award_type_ready) { create(:award_type, state: :ready) }
    let!(:award_published_ready) { create(:award_ready, award_type: award_type_ready) }
    let!(:award_type_draft) { create(:award_type, state: :draft) }
    let!(:award_type_pending) { create(:award_type, state: :pending) }
    let!(:award_unpublished_draft) { create(:award, award_type: award_type_draft, status: :unpublished) }
    let!(:award_unpublished_pending) { create(:award, award_type: award_type_pending, status: :unpublished) }

    it 'switches ready awards to unpublished if state becomes draft' do
      award_published_ready.update(account: nil)
      award_type_ready.update(state: :draft)
      expect(award_published_ready.reload.unpublished?).to be_truthy
    end

    it 'switches ready awards to unpublished if state becomes pending' do
      award_published_ready.update(account: nil)
      award_type_ready.update(state: :pending)
      expect(award_published_ready.reload.unpublished?).to be_truthy
    end

    it 'switches unpublished awards to ready if state becomes ready' do
      award_type_draft.update(state: :ready)
      award_type_pending.update(state: :ready)
      expect(award_unpublished_draft.reload.ready?).to be_truthy
      expect(award_unpublished_pending.reload.ready?).to be_truthy
    end
  end
end
