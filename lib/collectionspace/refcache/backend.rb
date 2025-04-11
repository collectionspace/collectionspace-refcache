# frozen_string_literal: true

require_relative "backend/activesupport_cache_store"
require_relative "backend/redis"
require_relative "backend/zache"

module CollectionSpace
  class RefCache
    module Backend
    end
  end
end
