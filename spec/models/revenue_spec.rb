require 'rails_helper'

describe Revenue do
  specify do
    validation_errors = Revenue.new.tap(&:valid?).errors.full_messages.sort
    expect(validation_errors.sort).to match ["Amount can't be blank",
                                             "Amount is not a number",
                                             "Currency can't be blank",
                                             "Project can't be blank",
                                            ].sort
  end

  specify do
    revenue = Revenue.new
    revenue.amount = -1
    expect(revenue.valid?).to eq(false)
    expect(revenue.errors[:amount]).to eq(["must be greater than 0"])
  end

  describe ".total_revenue" do
    describe 'with no revenue' do
      specify { expect(Revenue.total_amount).to eq(0) }
    end

    describe 'with project revenue' do
      let!(:project1) { create :project }
      let!(:project2) { create :project }

      before do
        project1.revenues.create(amount: 3, currency: 'USD')
        project1.revenues.create(amount: 5, currency: 'USD')

        project2.revenues.create(amount: 7, currency: 'USD')
        project2.revenues.create(amount: 11, currency: 'USD')
      end

      specify do
        expect(Revenue.total_amount).to eq(26)
      end

      it 'can be scoped to a project' do
        expect(project1.revenues.total_amount).to eq(8)
        expect(project2.revenues.total_amount).to eq(18)
      end
    end
  end
end