# frozen_string_literal: true

require "zache"

module CollectionSpace
  class RefCache
    module Backend
      class Rails
        def initialize(rails_cache)
          @c = rails_cache
        end

        def clean
          raise "not implemented"
        end

        def connected?
          "PONG" # cute, matches redis response
        end

        def exists?(key)
          !get(key).nil?
        end

        def flush
          @c.clear
        end

        def get(key)
          @c.fetch(key)
        rescue
          nil
        end

        def put(key, value, lifetime: nil)
          @c.fetch(key, expires_in: lifetime) { value }
        end

        def remove(key)
          @c.delete(key)
        end

        def size
          raise "not implemented"
        end
      end
    end
  end
end
