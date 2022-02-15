# frozen_string_literal: true

require 'redis'

module CollectionSpace
  class RefCache
    module Backend
      class Redis
        def initialize(url)
          # https://devcenter.heroku.com/articles/heroku-redis#connecting-in-rails
          @c = ::Redis.new(url: url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
        end

        def clean
          # blank method; Redis handles removal of expired keys automagically, as per
          #  https://redis.io/commands/expire
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
    end
  end
end
