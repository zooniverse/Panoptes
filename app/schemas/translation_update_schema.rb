class TranslationUpdateSchema < JsonSchema
  schema do
    type "object"
    description "A resource translation"
    required "strings"
    additional_properties false

    property "strings" do
      type "object"
    end

    property "string_versions" do
      type "object"
    end
  end
end
