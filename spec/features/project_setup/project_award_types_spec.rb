require 'rails_helper'

describe 'project award_types', js: true do
  let!(:current_auth) { create(:sb_authentication) }
  let!(:project1) { create(:sb_project, account: current_auth.account) }
  let!(:award_type1) { create(:award_type, name: 'First', project: project1) }
  let!(:award_type2) { create(:award_type, name: 'Second', project: project1) }
  let!(:award_type3) { create(:award_type, name: 'Third', project: project1) }
  let!(:award) { create(:award, award_type: award_type3) }

  before do
    login(current_auth.account)
  end

  it 'allows to create award_type' do
    visit project_award_types_path(project1)
    find('.batch-index--sidebar--item__bold', text: 'Create a New Batch').click
    expect(page).to have_content 'Create A New Batch'
    fill_in 'batch[name]', with: 'test name'
    fill_in 'batch[goal]', with: 'test goal'
    fill_in 'batch[description]', with: 'test description'
    find_button('create').click
    expect(page).to have_content 'Batch created'
    expect(AwardType.last.name).to eq 'test name'
    expect(AwardType.last.goal).to eq 'test goal'
    expect(AwardType.last.description).to eq 'test description'
  end

  it 'allows to edit award_type' do
    visit project_award_types_path(project1)
    find('.batch-index--sidebar--item', text: award_type1.name.capitalize).click
    find("a[href='#{edit_project_award_type_path(project1, award_type1)}']").click
    expect(page).to have_content 'Edit Batch'
    fill_in 'batch[name]', with: 'test name updated'
    find_button('save').click
    expect(page).to have_content 'Batch updated'
    expect(award_type1.reload.name).to eq 'test name updated'
  end

  it 'allows to delete award_type' do
    visit project_award_types_path(project1)
    find('.batch-index--sidebar--item', text: award_type2.name.capitalize).click
    find("a[data-method='delete'][href='#{project_award_type_path(project1, award_type2)}']").click
    expect(page).to have_content 'Batch destroyed'
  end

  it "doesn't allow to delete award_type if it has any awards" do
    visit project_award_types_path(project1)
    find('.batch-index--sidebar--item', text: award_type3.name.capitalize).click
    find("a[data-method='delete'][href='#{project_award_type_path(project1, award_type3)}']").click
    expect(page).to have_content 'Cannot delete record because dependent awards exist'
  end
end
