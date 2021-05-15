class ProjectDecorator < Draper::Decorator
  delegate_all
  include ActionView::Helpers::NumberHelper
  include Rails.application.routes.url_helpers

  PAYMENT_DESCRIPTIONS = {
    'project_token' => 'Project Tokens'
  }.freeze

  OUTSTANDING_AWARD_DESCRIPTIONS = {
    'project_token' => 'Project Tokens'
  }.freeze

  def description_html
    Comakery::Markdown.to_html(object.description)
  end

  def description_text_truncated(max_length = 60)
    helpers.strip_tags(description_html).truncate(max_length)
  end

  def status_description
    if project.license_finalized?
      'These terms are finalized and legally binding.'
    else
      'This is a draft of possible project terms that is not legally binding.'
    end
  end

  def hot_wallet_address
    hot_wallet&.address
  end

  def currency_denomination
    token&.decorate&.currency_denomination
  end

  def payment_description
    PAYMENT_DESCRIPTIONS[project.payment_type]
  end

  def outstanding_award_description
    OUTSTANDING_AWARD_DESCRIPTIONS[project.payment_type]
  end

  def require_confidentiality_text
    project.require_confidentiality ? 'is required' : 'is not required'
  end

  def exclusive_contributions_text
    project.exclusive_contributions ? 'are exclusive' : 'are not exclusive'
  end

  def total_awarded_pretty
    format_with_decimal_places(total_awarded)
  end

  def total_awarded_to_user(account)
    amount = account.total_awards_earned(self)
    format_with_decimal_places(amount)
  end

  def format_with_decimal_places(amount)
    if token && token.decimal_places.to_i.positive?
      number_to_currency(amount, precision: token.decimal_places, unit: '')
    else
      number_with_precision(amount, precision: 0, delimiter: ',')
    end
  end

  def maximum_tokens_pretty
    format_with_decimal_places(maximum_tokens)
  end

  def percent_awarded_pretty
    "#{number_with_precision(percent_awarded, precision: 3, delimiter: ',')}%"
  end

  def minimum_payment
    project_min_payment = Comakery::Currency::DEFAULT_MIN_PAYMENT[token.denomination]
    "#{currency_denomination}#{project_min_payment}"
  end

  def contributors_by_award_amount
    contributors_distinct.order_by_award(project)
  end

  def tokens_awarded_with_symbol
    token&.symbol ? "#{token.symbol} Tokens Awarded" : 'Tokens Awarded'
  end

  def send_coins?
    token&._token_type? && %w[eth btc ada qtum eos xtz].include?(token&._token_type)
  end

  def header_props
    project_image_path = GetImageVariantPath.call(
      attachment: panoramic_image,
      resize_to_fill: [1500, 300],
      fallback: helpers.asset_url('default_project.jpg')
    ).path

    {
      title: title,
      owner: legal_project_owner,
      image_url: project_image_path,
      settings_url: edit_project_path(self),
      access_url: project_dashboard_accesses_path(self),
      batches_url: project_award_types_path(self),
      transfers_url: project_dashboard_transfers_path(self),
      accounts_url: project_dashboard_accounts_path(self),
      transfer_rules_url: project_dashboard_transfer_rules_path(self),
      landing_url: unlisted? ? unlisted_project_path(long_id) : project_path(self),
      show_batches: award_types.where.not(state: :draft).any?,
      show_transfers: !require_confidentiality?,
      supports_transfer_rules: supports_transfer_rules?,
      whitelabel: whitelabel,
      github_url: github_url,
      documentation_url: documentation_url,
      getting_started_url: getting_started_url,
      governance_url: governance_url,
      funding_url: funding_url,
      video_conference_url: video_conference_url,
      present: true
    }
  end

  def team_top_limit
    8
  end

  def team_top
    team = (admins.with_attached_image.includes(:specialty).first(4).to_a.unshift(account) + top_contributors.to_a).uniq

    team += project_interested.with_attached_image.includes(:specialty).where.not(id: team.pluck(:id)).first(team_top_limit - team.size) if team.size < team_top_limit

    team
  end

  def team_size
    interested.size
  end

  def step_for_amount_input
    token ? (1.0 / 10**token.decimal_places) : 1
  end

  def step_for_quantity_input
    token ? 0.1 : 1
  end

  def image_url(size = 1000)
    GetImageVariantPath.call(
      attachment: square_image,
      resize_to_fill: [size, size],
      fallback: helpers.image_url('default_project.jpg')
    ).path
  end

  def transfers_chart_types
    project.transfer_types.pluck(:name).index_with { |_k| 0 }
  end

  def transfers_chart_colors
    project.transfer_types.pluck(:name).map.with_index { |t, i| [t, Comakery::ChartColors.lookup(i)] }.to_h
  end

  def transfers_chart_colors_objects
    project.transfer_types.map.with_index { |t, i| [t, Comakery::ChartColors.lookup(i)] }.to_h
  end

  def transfers_chart_amount(negative, amount)
    return -amount if negative

    amount
  end

  def transfers_stacked_chart(transfers, limit, grouping, date_modifier, empty, negative)
    chart = transfers_grouping(transfers, limit, grouping, date_modifier, negative)
    chart.concat(empty).uniq { |x| x[:timeframe] }.sort_by { |x| x[:i] }
  end

  def transfers_grouping(transfers, limit, grouping, date_modifier, negative)
    transfers.includes(:transfer_type).where('awards.created_at > ?', limit).group_by { |r| r.created_at.send(grouping) }.map do |timeframe, set|
      transfers_chart_types.merge(
        set.group_by(&:transfer_type).map { |k, v| [k.name, transfers_chart_amount(negative, v.sum(&:total_amount))] }.to_h.merge(
          timeframe: timeframe.strftime(date_modifier),
          i: timeframe.to_i
        )
      )
    end
  end

  def transfers_stacked_chart_year(transfers, negative: false)
    transfers_stacked_chart(
      transfers,
      10.years.ago,
      :beginning_of_year,
      '%Y',
      (10.years.ago.year..Time.current.year).map { |k| transfers_chart_types.merge(timeframe: k.to_s, i: DateTime.strptime(k.to_s, '%Y').to_i) },
      negative
    )
  end

  def transfers_stacked_chart_month(transfers, negative: false)
    transfers_stacked_chart(
      transfers,
      1.year.ago,
      :beginning_of_month,
      "%b%t'%y",
      (1.year.ago.beginning_of_month.to_date..Time.current.to_date).select { |d| d.day == 1 }.map { |k| transfers_chart_types.merge(timeframe: k.strftime("%b%t'%y"), i: k.to_time.to_i) },
      negative
    )
  end

  def transfers_stacked_chart_week(transfers, negative: false)
    transfers_stacked_chart(
      transfers,
      12.weeks.ago,
      :beginning_of_week,
      '%d%t%b',
      (12.weeks.ago.beginning_of_week.to_date..Time.current.to_date).each_slice(7).map { |k| transfers_chart_types.merge(timeframe: k.first.strftime('%d%t%b'), i: k.first.to_time.to_i) },
      negative
    )
  end

  def transfers_stacked_chart_day(transfers, negative: false)
    transfers_stacked_chart(
      transfers,
      1.week.ago,
      :beginning_of_day,
      '%a',
      (1.week.ago.to_date..Time.current.to_date).map { |k| transfers_chart_types.merge(timeframe: k.strftime('%a'), i: k.to_time.to_i) },
      negative
    )
  end

  def transfers_donut_chart(transfers) # rubocop:todo Metrics/CyclomaticComplexity
    completed_sum = awards.completed.sum(&:total_amount)
    filtered_sum = transfers.sum(&:total_amount)

    chart = transfers.group_by(&:transfer_type).map do |type, set|
      {
        name: type.name,
        value: set.sum(&:total_amount),
        ratio: ratio_pretty(set.sum(&:total_amount), completed_sum),
        ratio_filtered: ratio_pretty(set.sum(&:total_amount), filtered_sum)
      }
    end

    chart.concat(
      transfers_chart_types.map do |k, _|
        {
          name: k,
          value: 0,
          ratio: 0
        }
      end
    ).uniq { |x| x[:name] }
  end

  def ratio_pretty(value, total)
    return '100 %' if total.zero?

    ratio = (100 * value / total).round

    if ratio.zero?
      '< 1 %'
    elsif ratio == 100
      "#{ratio} %"
    else
      "≈ #{ratio} %"
    end
  end

  # rubocop:todo Metrics/PerceivedComplexity
  def project_transfers_csv_data # rubocop:todo Metrics/CyclomaticComplexity
    if project.token&.symbol
      amount_col = "Amount(#{project.token.symbol})"
      total_col = "Total(#{project.token.symbol})"
    else
      amount_col = 'Amount'
      total_col = 'Total'
    end

    column_names = ['Recipient User ID', 'Recipient First Name', 'Recipient Last Name', 'Recipient blockchain adddress', 'Sender First Name', 'Sender Last Name', 'Sender blockchain adddress', 'Transfer Name', 'Transfer Type', 'Account', 'Transfered By', amount_col, 'Quantity', total_col, 'Transaction', 'Transaction ID', 'Transfered', 'Created At'].freeze

    CSV.generate({ force_quotes: true, col_sep: ',' }) do |csv|
      csv << column_names
      project.awards.completed.includes(:award_type, :issuer, project: [:token]).order(:created_at).decorate.each do |transfer|
        transfer_transaction = if project.token && project.token&._token_type?
          if transfer.paid? && transfer.ethereum_transaction_explorer_url
            transfer.ethereum_transaction_address_short
          elsif transfer.project.token&.token_frozen?
            'frozen'
          elsif transfer.recipient_address.blank?
            'needs wallet'
          else
            'pending'
          end
        else
          '-'
        end

        account = transfer.account
        issuer = transfer.issuer

        csv << [transfer.account_id,
                account.first_name,
                account.last_name,
                transfer.recipient_address,
                issuer.first_name,
                issuer.last_name,
                transfer.issuer_address,
                transfer.name,
                transfer.transfer_type&.name,
                account ? account.decorate.name : transfer.email,
                transfer.paid? ? transfer.issuer.decorate.name : '–',
                transfer.amount_pretty,
                transfer.quantity,
                transfer.total_amount_pretty,
                transfer_transaction,
                transfer.ethereum_transaction_id,
                transfer.paid? && transfer.transferred_at ? transfer.transferred_at.strftime('%b %e %Y') : '–',
                transfer.created_at.strftime('%b %e %Y')]
      end
    end
  end

  def self.pretty_number(*currency_methods)
    currency_methods.each do |method_name|
      define_method "#{method_name}_pretty" do
        number_with_precision(send(method_name), precision: 0, delimiter: ',').to_s
      end
    end
  end

  pretty_number :maximum_tokens
end
