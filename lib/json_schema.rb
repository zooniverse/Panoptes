class JsonSchema
  class ValidationError < StandardError; end

  ERROR_FORMAT_REGEX = /'#\/(.*)'\s(.+)\sin/

  class Builder
    attr_reader :schema

    def initialize(schema={})
      @schema = schema
    end

    def build(&block)
      instance_exec(&block)
      schema
    end

    private

    def additional_properties(bool)
      schema[:additionalProperties] = bool
    end

    def title(title)
      schema[:title] = title
    end

    def type(*type)
      schema[:type] = type.length == 1 ? type.first : type
    end

    def pattern(pattern)
      schema[:pattern] = pattern
    end

    def description(desc)
      schema[:description] = desc
    end

    def required(*props)
      schema[:required] = props
    end

    def items(*items, &block)
      raise StandardError unless schema[:type] == 'array'
      schema[:items] = subschema(&block)
    end

    def property(prop, &block)
      raise StandardError unless schema[:type] == 'object'
      schema[:properties] ||= {}
      schema[:properties][prop.to_sym] = subschema(&block)
    end

    def one_of(*schemas)
      schema[:oneOf] = schemas.map do |schema|
        case schema
        when String, Symbol
          { "$refs" => "#/definitions/#{ schema }" }
        when Hash
          schema
        end
      end
    end

    def define(key, &block)
      schema[:definitions] ||= {}
      schema[:definitions][key.to_sym] = subschema(&block)
    end

    def subschema(&block)
      Builder.new.build(&block)
    end
  end

  def self.build(&block)
    new(Builder.new.build(&block))
  end

  def self.schema(&block)
    return @schema unless block_given?
    @schema = Builder.new.build(&block)
  end

  def initialize(schema=self.class.schema)
    @schema = schema
  end

  def validate!(json)
    errors = JSON::Validator.fully_validate(@schema, json.to_h)
    unless errors.empty?
      raise ValidationError, format_errors_to_hash(errors)
    end
  end

  def format_errors_to_hash(errors_array)
    formatted_errors = errors_array.collect do |error|
      field, message = error.scan(ERROR_FORMAT_REGEX).flatten
      [ field.blank? ? 'schema' : field, message ]
    end.flatten
    # TODO: bump to array.to_h when jruby supports MRI 2.2
    Hash[*formatted_errors]
  end
end
