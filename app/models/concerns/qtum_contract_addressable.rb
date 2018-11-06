module QtumContractAddressable
  extend ActiveSupport::Concern

  class QtumContractAddressValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      validate_format(record, attribute, value) if value.present?
      validate_immutable(record, attribute) if options[:immutable]
    end

    def validate_format(record, attribute, value)
      if value !~ /\A[0-9a-fA-F]{40}\z/
        message = options[:message] || 'should have 40 characters, ' \
          "should not start with '0x'"
        record.errors.add attribute, message
      end
    end

    def validate_immutable(record, attribute)
      if record.send("#{attribute}_was").present? && record.send("#{attribute}_changed?")
        record.errors.add attribute, 'cannot be changed after it has been set'
      end
    end
  end
end
