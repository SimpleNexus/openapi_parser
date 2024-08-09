# validate AllOf schema
class OpenAPIParser::SchemaValidator
  class AllOfValidator < Base
    # coerce and validate value
    # @param [Object] value
    # @param [OpenAPIParser::Schemas::Schema] schema
    # @param [Boolean] parent_all_of true if component is nested under allOf
    # @param [Array<String>, nil] remaining_keys array of unaccounted for properties from inherited object
    def coerce_and_validate(value, schema, parent_all_of: false, remaining_keys: nil, **keyword_args)
      if value.nil? && schema.nullable
        return [value, nil]
      end

      # if any schema return error, it's not valida all of value
      remaining_keys               ||= (value.kind_of?(Hash) ? value.keys : [])
      nested_additional_properties = false
      schema.all_of.each do |s|
        # We need to store the reference to all of, so we can perform strict check on allowed properties
        _coerced, err = validatable.validate_schema(
          value,
          s,
          :parent_all_of => true,
          :remaining_keys => remaining_keys,
          parent_discriminator_schemas: keyword_args[:parent_discriminator_schemas]
        )

        nested_additional_properties = true if s.type == "object" && s.additional_properties

        return [nil, err] if err
      end

      # If there are nested additionalProperties, we allow not defined extra properties and lean on the specific
      # additionalProperties validation
      if !nested_additional_properties && !parent_all_of && !remaining_keys.empty?
        return [nil, OpenAPIParser::NotExistPropertyDefinition.new(remaining_keys, schema.object_reference)]
      end

      [value, nil]
    end
  end
end
