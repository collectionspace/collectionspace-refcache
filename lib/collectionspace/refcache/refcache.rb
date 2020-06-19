# frozen_string_literal: true

require 'digest'
require 'zache'
require_relative 'search'

module CollectionSpace
  class RefCache
    include Search
    class ClientError < StandardError; end
    class NotFoundError < StandardError; end

    attr_reader :config, :domain
    def initialize(config: {}, client:)
      @cache = Zache.new
      @client = check_client(client)
      @domain = config.fetch(:domain)
      @error_if_not_found = config.fetch(:error_if_not_found, false)
      @lifetime = config.fetch(:lifetime, 5 * 60)
      @search_delay = config.fetch(:search_delay, 5 * 60)
      @search_enabled = config.fetch(:search_enabled, false)
      @search_identifiers = config.fetch(:search_identifiers, false)
    end

    # cache.clean # delete expired keys (run using cron etc.)
    def clean
      @cache.clean
    end

    def delay?(key)
      return false unless key.end_with?('_lock')

      @cache.exists?(key) && (Time.now - @search_delay) < @cache.get(key)
    end

    # cache.exists?('placeauthorities', 'place', 'Death Valley')
    def exists?(type, subtype, value)
      key = generate_key([type, subtype, value])
      @cache.exists?(key)
    end

    def generate_key(parts = [])
      Digest::SHA2.hexdigest(parts.dup.append(domain).join)
    end

    # cache.get('placeauthorities', 'place', 'The Moon')
    # cache.get('vocabularies', 'languages', 'English')
    def get(type, subtype, value)
      key = generate_key([type, subtype, value])
      lock = "#{key}_lock"
      refname = @cache.get(key, lifetime: @lifetime) do
        return nil unless @search_enabled
        return nil if delay?(lock)

        search(type, subtype, value)
      end

      unless refname
        @cache.remove(key)
        @cache.put(lock, Time.now, lifetime: @search_delay) unless delay?(lock)
        raise NotFoundError if @error_if_not_found
      end

      refname
    end

    # cache.put('placeauthorities', 'place', 'The Moon', $refname)
    def put(type, subtype, value, refname)
      key = generate_key([type, subtype, value])
      @cache.put(key, refname, lifetime: @lifetime)
    end

    private

    def check_client(client)
      raise ClientError unless client.is_a? CollectionSpace::Client

      client
    end
  end
end
