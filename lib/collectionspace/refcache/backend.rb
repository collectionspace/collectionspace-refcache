# frozen_string_literal: true

module CollectionSpace
  class RefCache
    module Backend
      class Redis
        def initialize(url)
          # https://devcenter.heroku.com/articles/heroku-redis#connecting-in-rails
          @c = ::Redis.new(url: url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
        end

        def clean
          @c.flushdb
        end

        def connected?
          @c.ping rescue false
        end

        def exists?(key)
          @c.exists?(key)
        end

        def get(key)
          @c.get(key)
        end

        def put(key, value, lifetime: nil)
          @c.set(key, value, ex: lifetime)
        end

        def remove(key)
          @c.del(key)
        end

        def size
          @c.dbsize
        end
      end

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
