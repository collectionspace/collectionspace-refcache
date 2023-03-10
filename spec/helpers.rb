# frozen_string_literal: true

module Helpers
  module_function

  def populate_cache(cache)
    cache.put("a", "b", "c", "d")
    cache.put("e", "f", "g", "h")
    cache.put("i", "j", "k", "l")
  end
end
