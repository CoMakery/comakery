class ProjectDecorator < Draper::Decorator
  delegate_all
  include ActionView::Helpers::NumberHelper

  PAYMENT_DESCRIPTIONS = {
      "revenue_share" => "Revenue Shares",
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

  def royalty_percentage_pretty
    return "0%" if project.royalty_percentage.blank?
    "#{project.royalty_percentage}%"
  end

  def require_confidentiality_text
    project.require_confidentiality ? "is required" : "is not required"
  end

  def exclusive_contributions_text
    project.exclusive_contributions ? "are exclusive" : "are not exclusive"
  end

  def balance_pretty
    "#{currency_denomination}0"
  end

  def my_balance_pretty
    "#{currency_denomination}0"
  end

  def total_revenue_pretty
    "#{currency_denomination}#{number_with_precision(total_revenue, precision: 2, delimiter: ',')}"
  end

  def total_revenue_shared_pretty
    "#{currency_denomination}#{number_with_precision(total_revenue_shared, precision: 2, delimiter: ',')}"
  end

  def revenue_per_share_pretty
    "#{currency_denomination}#{number_with_precision(revenue_per_share, precision: 4, delimiter: ',')}"
  end


  def minimum_revenue
    "#{currency_denomination}0"
  end

  def minimum_payment
    "#{currency_denomination}10"
  end

  def revenue_history
    project.revenues.order(created_at: :desc, id: :desc).decorate
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
