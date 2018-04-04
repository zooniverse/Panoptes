class HttpCacheable
  CACHEABLE_RESOURCES = %i(subjects projects workflows).freeze

  attr_reader :controlled_resources, :resource_class, :resource_symbol

  def initialize(controlled_resources)
    @controlled_resources = controlled_resources
    @resource_class = controlled_resources.klass
    @resource_symbol = resource_class.model_name.plural.to_sym
  end

  def cacheable?
    return false unless cacheable_resource?
    !any_private_resources?
  end

  def resource_cache_directive
    return unless cacheable?

    @resource_cache_directive ||=
      "#{public_private_directive}, max-age=#{max_age_directive}"
  end

  private

  def any_private_resources?
    controlled_resources.private_scope.exists?
  end

  def public_private_directive
    @public_private_directive ||=
      if Panoptes.flipper[:private_http_caching].enabled?
        "private"
      else
        "public"
      end
  end

  def max_age_directive
    @max_age_directive ||= ENV.fetch("HTTP_#{resource_symbol.to_s.upcase}_MAX_AGE", 60)
  end

  def cacheable_resource?
    Panoptes.flipper[:http_caching].enabled? &&
      CACHEABLE_RESOURCES.include?(resource_symbol)
  end
end
