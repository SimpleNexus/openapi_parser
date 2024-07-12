class OpenAPIParser::SchemaValidator
  class StringValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def initialize(validator, coerce_value, datetime_coerce_class, validate_read_only, validate_write_only, custom_string_formats)
      super(validator, coerce_value, validate_read_only, validate_write_only)
      @datetime_coerce_class = datetime_coerce_class
      @custom_string_formats = custom_string_formats || {}
    end

    def coerce_and_validate(value, schema, **_keyword_args)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(String)

      value, err = check_enum_include(value, schema)
      raise err if err

      value = validate_pattern(value, schema)
      value = validate_max_min_length(value, schema)
      value = validate_email_format(value, schema)
      value = validate_uuid_format(value, schema)
      value = validate_uri_format(value, schema)
      value = validate_date_format(value, schema)
      value = validate_datetime_format(value, schema)
      value = validate_custom_string_formats(value, schema)

      return [value, nil]
    rescue OpenAPIParser::OpenAPIError => err
      return [nil, err]
    end

    private

      # @param [OpenAPIParser::Schemas::Schema] schema
      def validate_pattern(value, schema)
        # pattern support string only so put this
        return value unless schema.pattern
        return value if value =~ /#{schema.pattern}/

        raise OpenAPIParser::InvalidPattern.new(value, schema.pattern, schema.object_reference, schema.example)
      end

      def validate_max_min_length(value, schema)
        raise OpenAPIParser::MoreThanMaxLength.new(value, schema.object_reference) if schema.maxLength && value.size > schema.maxLength
        raise OpenAPIParser::LessThanMinLength.new(value, schema.object_reference) if schema.minLength && value.size < schema.minLength
        return value
      end

      def validate_email_format(value, schema)
        return value unless schema.format == 'email'
        return value if value.match(URI::MailTo::EMAIL_REGEXP)

        raise OpenAPIParser::InvalidStringFormat.new(value, schema.object_reference, schema.format)
      end

      def validate_uuid_format(value, schema)
        return value unless schema.format == 'uuid'
        return value if value.match(/[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/)

        raise OpenAPIParser::InvalidStringFormat.new(value, schema.object_reference, schema.format)
      end

      def validate_uri_format(value, schema)
        return value unless schema.format =~ /\A(?:[a-zA-Z_]+_)?uri\z/
        if schema.format.end_with?("_uri")
          protocols = schema.format.split("_")[...-1]
          protocols << "https" if protocols.any?("http")
          protocols.uniq!
        end

        return value if value.match(/\A#{URI.regexp(protocols)}\z/)

        raise OpenAPIParser::InvalidStringFormat.new(value, schema.object_reference, schema.format)
      end

      def validate_date_format(value, schema)
        return value unless schema.format == 'date'

        begin
          Date.strptime(value, "%Y-%m-%d")
        rescue ArgumentError
          raise OpenAPIParser::InvalidStringFormat.new(value, schema.object_reference, schema.format)
        end

        return value
      end

      def validate_datetime_format(value, schema)
        return value unless schema.format == 'date-time'

        begin
          if @datetime_coerce_class.nil?
            # validate only
            DateTime.rfc3339(value)
            return value
          else
            # validate and coerce
            if @datetime_coerce_class == Time
              return DateTime.rfc3339(value).to_time
            else
              return @datetime_coerce_class.rfc3339(value)
            end
          end
        rescue ArgumentError
          # when rfc3339(value) failed
          raise OpenAPIParser::InvalidStringFormat.new(value, schema.object_reference, schema.format)
        end
      end

      def validate_custom_string_formats(value, schema)
        return value if schema.format.nil?
        @custom_string_formats.each do |format, regexp|
          next unless schema.format.to_s == format.to_s
          break if value.match(regexp)
          raise OpenAPIParser::InvalidStringFormat.new(value, schema.object_reference, schema.format)
        end

        return value
      end
  end
end
