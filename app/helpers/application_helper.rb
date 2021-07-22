module ApplicationHelper
  include Turbo::FramesHelper
  include Turbo::StreamsHelper

  def account_image_url(account, size)
    GetImageVariantPath.call(
      attachment: account&.image,
      resize_to_fill: [size, size],
      fallback: asset_url('user-icon.svg')
    ).path
  end

  def project_image_url(obj, size)
    GetImageVariantPath.call(
      attachment: obj&.square_image,
      resize_to_fill: [size, size],
      fallback: asset_url('default_project.jpg')
    ).path
  end

  def project_page
    if controller_name == 'projects'
      params[:action]
    else
      controller_name
    end
  end

  def ransack_filter_present?(query, name, predicate, value) # rubocop:todo Metrics/CyclomaticComplexity
    query.conditions.any? do |c|
      return false unless c.predicate.name == predicate
      return false unless c.attributes.any? { |a| a.name == name }
      return false unless c.values.any? { |v| v.value == value }

      true
    end
  end

  def transfer_type(transfer_type_id)
    TransferType.find(transfer_type_id)
  end

  def transfers_totals_data(transfers_totals)
    { total_transfers: transfers_totals.size,
      total_accounts: transfers_totals.pluck(:account_id).uniq.size,
      total_admins: transfers_totals.paid.pluck(:issuer_id).uniq.size,
      total_quantity: transfers_totals.sum(&:quantity),
      total_amount: transfers_totals.sum(&:total_amount) }
  end

  def transfer_account(account_id)
    Account.includes(:ore_id_account).find_by(id: account_id)
  end

  def middle_truncate(str, length: 5)
    return str if str.length <= length * 2

    str.truncate(length, omission: "#{str.first(length)}...#{str.last(length)}")
  end

  def flash_to_array
    %i[notice warning error].map do |severity|
      flash[severity] ? { severity: severity, text: html_escape(flash[severity]) } : nil
    end.compact
  end

  def deploy_to_heroku_url(project)
    token = project.token
    params = {
      env: {
        PROJECT_ID: project.id,
        COMAKERY_SERVER_URL: "#{request.protocol}#{request.host_with_port}",
        BLOCKCHAIN_NETWORK: token._blockchain
      }
    }

    if token._token_type_on_ethereum?
      token_type = ethereum_token_type(token)
      approval_address =
        case token_type
        when 'erc20_batch' then token.batch_contract_address
          # when 'token_release_schedule' then ???
        end

      params[:env][:INFURA_PROJECT_ID] = ENV['INFURA_PROJECT_ID']
      params[:env][:ETHEREUM_TOKEN_TYPE] = token_type
      params[:env][:ETHEREUM_TOKEN_SYMBOL] = token.symbol
      params[:env][:ETHEREUM_CONTRACT_ADDRESS] = token.contract_address
      params[:env][:ETHEREUM_APPROVAL_CONTRACT_ADDRESS] = approval_address if token_type.in?(%w[erc20_batch token_release_schedule])
    elsif token._token_type_on_algorand?
      params[:env][:PURESTAKE_API] = ENV['PURESTAKE_API']
      params[:env][:OPT_IN_APP] = token.contract_address
    end

    "https://heroku.com/deploy?template=https://github.com/CoMakery/comakery-server/tree/hotwallet&#{params.to_param}"
  end

  def ethereum_token_type(token)
    return 'erc20_batch' if token._token_type == 'erc20' && token.batch_contract_address.present?

    token._token_type
  end

  def active_class(link_path)
    current_page?(link_path) ? 'active' : ''
  end
end
