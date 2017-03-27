class ProjectDecorator < Draper::Decorator
  delegate_all
  include ActionView::Helpers::NumberHelper

  PAYMENT_DESCRIPTIONS = {
      "revenue_share" => "Revenue Shares",
      "project_coin" => "Project Coins",
  }

  OUTSTANDING_AWARD_DESCRIPTIONS = {
      "revenue_share" => "Unpaid Revenue Shares",
      "project_coin" => "Project Coins",
  }

  def description_html
    Comakery::Markdown.to_html(object.description)
  end

  def description_text(max_length = 90)
    Comakery::Markdown.to_text(object.description).truncate(max_length)
  end

  def ethereum_contract_explorer_url
    if ethereum_contract_address
      "https://#{Rails.application.config.ethercamp_subdomain}.ether.camp/account/#{project.ethereum_contract_address}"
    else
      nil
    end
  end

  def status_description
    if project.license_finalized?
      "These terms are finalized and legally binding."
    else
      "This is a draft of possible project terms that is not legally binding."
    end
  end

  def currency_denomination
    Comakery::Currency::DENOMINATIONS[project.denomination]
  end

  def payment_description
    PAYMENT_DESCRIPTIONS[project.payment_type]
  end

  def outstanding_award_description
    OUTSTANDING_AWARD_DESCRIPTIONS[project.payment_type]
  end

  def royalty_percentage_pretty
    return "0%" if project.royalty_percentage.blank?
    "#{number_with_precision(project.royalty_percentage, precision: 13, strip_insignificant_zeros: true)}%"
  end

  def require_confidentiality_text
    project.require_confidentiality ? "is required" : "is not required"
  end

  def exclusive_contributions_text
    project.exclusive_contributions ? "are exclusive" : "are not exclusive"
  end

  def total_revenue_pretty
    precision = Comakery::Currency::PRECISION[denomination]
    "#{currency_denomination}#{number_with_precision(total_revenue.truncate(precision),
                                                     precision: precision,
                                                     delimiter: ',')}"
  end

  def total_revenue_shared_pretty
    precision = Comakery::Currency::PRECISION[denomination]
    "#{currency_denomination}#{number_with_precision(total_revenue_shared.truncate(precision),
                                                     precision: precision,
                                                     delimiter: ',')}"
  end

  def total_awards_outstanding_pretty
    # awards (e.g. project coins or revenue shares) are validated as whole numbers; they are rounded
    number_with_precision(total_awards_outstanding, precision: 0, delimiter: ',')
  end

  def total_awarded_pretty
    number_with_precision(total_awarded, precision: 0, delimiter: ',')
  end

  def total_awards_redeemed_pretty
    number_with_precision(total_awards_redeemed, precision: 0, delimiter: ',')
  end

  def revenue_per_share_pretty
    precision = Comakery::Currency::PER_SHARE_PRECISION[denomination]
    "#{currency_denomination}#{number_with_precision(revenue_per_share.truncate(precision),
                                                     precision: precision,
                                                     delimiter: ',')}"
  end

  def total_revenue_shared_unpaid_pretty
    precision = Comakery::Currency::ROUNDED_BALANCE_PRECISION[denomination]
    "#{currency_denomination}#{number_with_precision(total_revenue_shared_unpaid.truncate(precision),
                                                     precision: precision,
                                                     delimiter: ',')}"
  end

  def total_paid_to_contributors_pretty
    precision = Comakery::Currency::ROUNDED_BALANCE_PRECISION[denomination]
    "#{currency_denomination}#{number_with_precision(total_paid_to_contributors.truncate(precision),
                                                     precision: precision,
                                                     delimiter: ',')}"
  end

  def minimum_revenue
    "#{currency_denomination}0"
  end

  def minimum_payment
    project_min_payment = Comakery::Currency::DEFAULT_MIN_PAYMENT[denomination]
    "#{currency_denomination}#{project_min_payment}"
  end

  def revenue_history
    project.revenues.order(created_at: :desc, id: :desc).decorate
  end

  def payment_history
    project.payments.order(created_at: :desc, id: :desc)
  end


  def share_of_revenue_unpaid_pretty(users_project_coins)
    precision = Comakery::Currency::ROUNDED_BALANCE_PRECISION[denomination]
    "#{currency_denomination}#{number_with_precision(share_of_revenue_unpaid(users_project_coins).truncate(precision),
                                                     precision: precision,
                                                     delimiter: ',')}"
  end

  def revenue_sharing_end_date_pretty
    return "revenue sharing does not have an end date." unless project.revenue_sharing_end_date.present?
    project.revenue_sharing_end_date.strftime('%B %-d, %Y')
  end

  def contributors_by_award_amount
    contributors_distinct.decorate.to_a.sort_by {|c| c.total_awards_earned(project) }.reverse!
  end

  private


  def self.pretty_number(*currency_methods)
    currency_methods.each do |method_name|
      define_method "#{method_name}_pretty" do
        "#{number_with_precision(self.send(method_name), precision: 0, delimiter: ',')}"
      end
    end
  end

  pretty_number :maximum_royalties_per_month, :maximum_coins
end
