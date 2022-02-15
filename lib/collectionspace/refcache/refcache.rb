# frozen_string_literal: true

require 'digest'
require 'redis'
require 'zache'

module CollectionSpace
  class RefCache
    class NotFoundError < StandardError; end

    attr_reader :config, :domain
    def initialize(config: {})
      @cache = backend(config.fetch(:redis, nil))
      @domain = config.fetch(:domain)
      @error_if_not_found = config.fetch(:error_if_not_found, false)
      @lifetime = config.fetch(:lifetime, 5 * 60)
    end

    # cache.clean # delete expired keys (run using cron etc.)
    def clean
      @cache.clean
    end

    def connected?
      @cache.connected?
    end

    # cache.exists?('placeauthorities', 'place', 'Death Valley')
    def exists?(type, subtype, value)
      key = generate_key([type, subtype, value])
      @cache.exists?(key)
    end

    def generate_key(parts = [])
      Digest::SHA2.hexdigest(parts.dup.append(domain).join).prepend('refcache::')
    end

    # cache.get('placeauthorities', 'place', 'The Moon')
    # cache.get('vocabularies', 'languages', 'English')
    def get(type, subtype, value)
      key = generate_key([type, subtype, value])
      @cache.get(key)
    end

    # cache.put('placeauthorities', 'place', 'The Moon', $refname)
    def put(type, subtype, value, refname)
      key = generate_key([type, subtype, value])
      @cache.put(key, refname, lifetime: @lifetime)
    end

    def size
      @cache.size
    end

    private

    def backend(connection)
      connection ? Backend::Redis.new(connection) : Backend::Zache.new
    end
  end
end
