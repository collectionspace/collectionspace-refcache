# frozen_string_literal: true

require 'zache'

module CollectionSpace
  class RefCache
    module Backend
      class Zache
        def initialize
          @c = ::Zache.new
        end

        def clean
          @c.clean
        end

        def connected?
          'PONG' # cute, matches redis response
        end

        def exists?(key)
          @c.exists?(key)
        end

        def get(key)
          @c.get(key) rescue nil
        end

        def put(key, value, lifetime: nil)
          @c.put(key, value, lifetime: lifetime)
        end

        def remove(key)
          @c.remove(key)
        end

        def size
          @c.size
        end
      end
    end
  end
end
