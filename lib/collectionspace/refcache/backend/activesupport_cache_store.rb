# frozen_string_literal: true

module CollectionSpace
  class RefCache
    module Backend
      class ActivesupportCacheStore
        # @param store [ActiveSupport::Cache::Store] or other store conforming
        #   to its abstract interface (e.g. SolidCache::Store)
        def initialize(store)
          @c = store
        end

        def clean
          return nil unless @c.respond_to?(:clean)

          @c.clean
        end

        def connected?
          "PONG" # cute, matches redis response
        end

        def exists?(key)
          @c.exist?(key)
        end

        def flush
          return nil unless @c.respond_to?(:clear)

          @c.clear
        end

        def get(key)
          @c.read(key)
        end

        def put(key, value, lifetime: nil)
          if lifetime
            @c.write(key, value, expires_in: lifetime)
            else
              @c.write(key, value)
          end
        end

        def remove(key)
          @c.delete(key)
        end

        def size
          return nil unless @c.respond_to?(:stats)

          @c.stats.dig(:connection_stats, :cache, :entries)
        end
      end
    end
  end
end
