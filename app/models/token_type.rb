class TokenType
  # See `app/models/token_type/*`

  attr_reader :attrs

  def initialize(**attrs)
    @attrs = attrs
  end

  # List of available types as an attribute for enum definition
  def self.list
    h = { btc: 0, ada: 1, qtum: 2, qrc20: 3, eos: 4, xtz: 5, dag: 6, eth: 7, erc20: 8, comakery_security_token: 9, asa: 10, algo: 11, algorand_security_token: 12, token_release_schedule: 13 } # Populated automatically by TokenTypeGenerator

    h.values.uniq.size == h.values.size ? h : raise('Invalid list of token types')
  end

  def self.append_to_list(token_type)
    list.merge(token_type => (list.values.max + 1))
  end

  def self.all
    list.keys.map { |k| "TokenType::#{k.to_s.camelize}".constantize.new }
  end

  def self.with_balance_support
    all.select(&:supports_balance?)
  end

  def self.with_balance_support_list
    with_balance_support.map { |t| t.class.to_s.demodulize.underscore }
  end
end
