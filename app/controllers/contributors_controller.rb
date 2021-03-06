class ContributorsController < ApplicationController
  before_action :assign_project
  skip_before_action :require_login, only: :index
  skip_after_action :verify_policy_scoped, only: [:index]

  layout 'legacy'

  def index # rubocop:todo Metrics/CyclomaticComplexity
    authorize @project, :show_contributions?

    @contributors  = @project.contributors_by_award_amount.page(params[:page])
    @award_data    = GetContributorData.call(project: @project).award_data

    @chart_data = @award_data[:contributions_summary_pie_chart].map do |award|
      {
        label: award[:name],
        value: award[:net_amount]
      }
    end

    @table_data = @contributors.decorate.map do |contributor|
      {
        image_url: helpers.account_image_url(contributor, 27),
        name: contributor.name,
        awards: contributor.award_by_project(@project).map do |award|
          {
            name: award[:name],
            total: @project.format_with_decimal_places(award[:total])
          }
        end,
        total: @project.format_with_decimal_places(contributor.total),
        total_dec: contributor.total
      }
    end

    # rubocop:todo Lint/SafeNavigationChain
    @table_data += @project.awards&.completed&.reject(&:account)&.group_by { |award| award.decorate.recipient_display_name }.values.map do |awards|
      # rubocop:enable Lint/SafeNavigationChain
      {
        image_url: helpers.account_image_url(nil, 27),
        name: awards.first.decorate.recipient_display_name,
        awards: [],
        total: @project.format_with_decimal_places(awards.sum(&:total_amount)),
        total_dec: awards.sum(&:total_amount),
        remaining: nil,
        unpaid: nil,
        paid: nil
      }
    end

    @table_data.sort_by! { |c| c[:total_dec] || 0 }.reverse!
  end
end
