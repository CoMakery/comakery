require 'rails_helper'

describe ProjectTokensIssued do
  let!(:project) { create(:sb_project) }
  let!(:auth1) { create(:sb_authentication) }
  let!(:auth2) { create(:sb_authentication) }
  let!(:award_type_1) { create(:award_type, project: project, amount: 1) }
  let!(:award_type_2) { create(:award_type, project: project, amount: 2) }
  let!(:award_type_4) { create(:award_type, project: project, amount: 4) }

  let!(:cc_project) { create(:cc_project) }
  let!(:cc_award) { create(:award, award_type: create(:award_type, project: cc_project, amount: 1000)) }

  it "returns 0 for projects with no awards" do
    project = create(:project)

    expect(ProjectTokensIssued.call(project: project).total_tokens_issued).to eq(0)

    create(:award_type, project: project)

    expect(ProjectTokensIssued.call(project: project).total_tokens_issued).to eq(0)
  end

  describe do
    before do
      create(:award, authentication: auth1, award_type: award_type_1)
      create(:award, authentication: auth1, award_type: award_type_2)
      create(:award, authentication: auth1, award_type: award_type_4)

      create(:award, authentication: auth2, award_type: award_type_1)
      create(:award, authentication: auth2, award_type: award_type_2)
      create(:award, authentication: auth2, award_type: award_type_4)
    end

    it "returns the total amount of tokens awarded for a project" do
      result = ProjectTokensIssued.call(project: project)
      expect(result).to be_success
      expect(result.total_tokens_issued).to eq(1 + 2 + 4 +
                                                  1 + 2 + 4)
    end

    it "returns the total amount of tokens awarded for a project with multiple award.quantity" do
      create(:award, authentication: auth2, award_type: award_type_4, quantity: 2)

      result = ProjectTokensIssued.call(project: project)
      expect(result).to be_success
      expect(result.total_tokens_issued).to eq(1 + 2 + 4 + 1 + 2 + 4 +
                                                  8)
    end
  end
end
