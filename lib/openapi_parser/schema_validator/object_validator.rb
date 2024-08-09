class OpenAPIParser::SchemaValidator
  class ObjectValidator < Base
    # @param [Hash] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    # @param [Boolean] parent_all_of true if component is nested under allOf
    # @param [String, nil] discriminator_property_name discriminator.property_name to ignore checking additional_properties
    # @param [Array<String>, nil] remaining_keys array of unaccounted for properties from inherited object
    def coerce_and_validate(value, schema, parent_all_of: false, remaining_keys: nil, parent_discriminator_schemas: [], discriminator_property_name: nil)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(Hash)

      properties = schema.properties.dup || {}

      required_set = schema.required ? schema.required.to_set : Set.new
      # If validate read only is false, remove read only properties from the required set.
      unless @validate_read_only
        read_only_set = properties.map{ |k, v| v.read_only ? k : nil}.compact.to_set
        required_set -= read_only_set
        properties.delete_if { |_, v| v.read_only }
      end
      # If validate write only is false, remove write only properties from the required set.
      unless @validate_write_only
        write_only_set = properties.map{ |k, v| v.write_only ? k : nil}.compact.to_set
        required_set -= write_only_set
        properties.delete_if{ |_, v| v.write_only }
      end

      remaining_keys ||= value.keys

      if schema.discriminator && !parent_discriminator_schemas.include?(schema)
        return validate_discriminator_schema(
          schema.discriminator,
          value,
          parent_discriminator_schemas: parent_discriminator_schemas + [schema]
        )
      else
        remaining_keys.delete('discriminator')
      end

      coerced_values = value.map do |name, v|
        s = properties[name]
        coerced, err = if s
                         remaining_keys.delete(name)
                         validatable.validate_schema(v, s)
                       else
                         # TODO: we need to perform a validation based on schema.additional_properties here, if
                         # additionalProperties are defined
                         [v, nil]
                       end

        return [nil, err] if err

        required_set.delete(name)
        [name, coerced]
      end

      remaining_keys.delete(discriminator_property_name) if discriminator_property_name

      if !remaining_keys.empty? && !parent_all_of && !schema.additional_properties
        # If object is nested in all of, the validation is already done in allOf validator. Or if
        # additionalProperties are defined, we will validate using that
        return [nil, OpenAPIParser::NotExistPropertyDefinition.new(remaining_keys, schema.object_reference)]
      end
      return [nil, OpenAPIParser::NotExistRequiredKey.new(required_set.to_a, schema.object_reference)] unless required_set.empty?

      value.merge!(coerced_values.to_h) if @coerce_value

      [value, nil]
    end
  end
end
