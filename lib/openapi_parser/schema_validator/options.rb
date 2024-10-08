class OpenAPIParser::SchemaValidator
  class Options
    # @!attribute [r] coerce_value
    #   @return [Boolean] coerce value option on/off
    # @!attribute [r] datetime_coerce_class
    #   @return [Object, nil] coerce datetime string by this Object class
    # @!attribute [r] validate_header
    #   @return [Boolean] validate header or not
    # @!attribute [r] validate_read_only
    #   @return [Boolean] validate readOnly properties or not
    # @!attribute [r] validate_write_only
    #   @return [Boolean] validate writeOnly properties or not
    attr_reader :coerce_value, :datetime_coerce_class, :validate_header, :validate_read_only, :validate_write_only, :custom_string_formats

    def initialize(coerce_value: nil, datetime_coerce_class: nil, validate_header: true, validate_read_only: false, validate_write_only: true, custom_string_formats: {})
      @coerce_value = coerce_value
      @datetime_coerce_class = datetime_coerce_class
      @validate_header = validate_header
      @validate_read_only = validate_read_only
      @validate_write_only = validate_write_only
      @custom_string_formats = custom_string_formats
    end
  end

  # response body validation option
  class ResponseValidateOptions
    # @!attribute [r] strict
    #   @return [Boolean] validate by strict (when not exist definition, raise error)
    attr_reader :strict, :validate_header

    def initialize(strict: false, validate_header: true)
      @strict = strict
      @validate_header = validate_header
      @validate_write_only = false
      @validate_read_only = true
      @custom_string_formats = {}
    end
  end
end
