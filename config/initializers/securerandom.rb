# backport from https://github.com/rails/rails/blob/ccbf1597b793e8de11b2cd19dd18f18d0b0b2182/activesupport/lib/active_support/core_ext/securerandom.rb

require 'securerandom'

module SecureRandom

  unless self.respond_to?(:base58)

    BASE58_ALPHABET = ('0'..'9').to_a  + ('A'..'Z').to_a + ('a'..'z').to_a - ['0', 'O', 'I', 'l']
    # SecureRandom.base58 generates a random base58 string.
    #
    # The argument _n_ specifies the length, of the random string to be generated.
    #
    # If _n_ is not specified or is nil, 16 is assumed. It may be larger in the future.
    #
    # The result may contain alphanumeric characters except 0, O, I and l
    #
    #   p SecureRandom.base58 # => "4kUgL2pdQMSCQtjE"
    #   p SecureRandom.base58(24) # => "77TMHrHJFvFDwodq8w7Ev2m7"
    #
    def self.base58(n = 16)
      SecureRandom.random_bytes(n).unpack("C*").map do |byte|
        idx = byte % 64
        idx = SecureRandom.random_number(58) if idx >= 58
        BASE58_ALPHABET[idx]
      end.join
    end

  end
end
