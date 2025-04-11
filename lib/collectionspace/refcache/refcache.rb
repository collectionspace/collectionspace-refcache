# frozen_string_literal: true

require "digest"

module CollectionSpace
  class Refcache
    class NotFoundError < StandardError; end

    attr_reader :config, :domain

    def initialize(config: {})
      @config = config
      @cache = set_backend(config)
      @domain = config.fetch(:domain)
      @error_if_not_found = config.fetch(:error_if_not_found, false)
      @lifetime = config.fetch(:lifetime, 5 * 60)
    end

    #####
    # General cache operations
    #####

    # deletes expired keys (run using cron etc.)
    def clean
      @cache.clean
    end

    def connected?
      @cache.connected?
    end

    # delete all keys from the cache
    #
    # If Redis backend, only deletes keys from active database
    def flush
      @cache.flush
    end

    def size
      @cache.size
    end

    #####
    # Default methods (assumes authority terms)
    # cache.exists?('placeauthorities', 'place', 'Death Valley')
    def exists?(type, subtype, value, value_type = nil)
      generic_exists?(term_key(type, subtype, value, value_type))
    end

    # cache.put('placeauthorities', 'place', 'The Moon', $refname)
    # rubocop:disable Metrics/ParameterLists
    def put(type, subtype, value, to_cache, value_type = nil)
      put_generic(term_key(type, subtype, value, value_type), to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    # cache.get('placeauthorities', 'place', 'The Moon')
    # cache.get('vocabularies', 'languages', 'English')
    def get(type, subtype, value, value_type = nil)
      get_generic(term_key(type, subtype, value, value_type))
    end

    def remove(type, subtype, value, value_type = nil)
      remove_generic(term_key(type, subtype, value, value_type))
    end

    #####
    # object caching
    #####
    def put_object(id, to_cache, value_type = nil)
      put_generic(object_key(id, value_type), to_cache)
    end

    def get_object(id, value_type = nil)
      get_generic(object_key(id, value_type))
    end

    def remove_object(id, value_type = nil)
      remove_generic(object_key(id, value_type))
    end

    def object_exists?(id, value_type = nil)
      generic_exists?(object_key(id, value_type))
    end

    #####
    # procedure caching
    #####
    def put_procedure(type, id, to_cache, value_type = nil)
      put_generic(procedure_key(type, id, value_type), to_cache)
    end

    def get_procedure(type, id, value_type = nil)
      get_generic(procedure_key(type, id, value_type))
    end

    def remove_procedure(type, id, value_type = nil)
      remove_generic(procedure_key(type, id, value_type))
    end

    def procedure_exists?(type, id, value_type = nil)
      generic_exists?(procedure_key(type, id, value_type))
    end

    #####
    # authority term caching
    #####
    def auth_term_exists?(type, subtype, term, value_type = nil)
      generic_exists?(term_key(type, subtype, term, value_type))
    end

    # rubocop:disable Metrics/ParameterLists
    def put_auth_term(type, subtype, term, to_cache, value_type = nil)
      put_generic(term_key(type, subtype, term, value_type), to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    def get_auth_term(type, subtype, term, value_type = nil)
      get_generic(term_key(type, subtype, term, value_type))
    end

    def remove_auth_term(type, subtype, term, value_type = nil)
      remove_generic(term_key(type, subtype, term, value_type))
    end

    #####
    # relation caching
    #####
    def relation_exists?(reltype, subjectcsid, objectcsid, value_type = nil)
      generic_exists?(
        relation_key(reltype, subjectcsid, objectcsid, value_type)
      )
    end

    # rubocop:disable Metrics/ParameterLists
    def put_relation(reltype, subjectcsid, objectcsid, to_cache,
      value_type = nil)
      put_generic(relation_key(reltype, subjectcsid, objectcsid, value_type),
        to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    def get_relation(reltype, subjectcsid, objectcsid, value_type = nil)
      get_generic(relation_key(reltype, subjectcsid, objectcsid, value_type))
    end

    def remove_relation(reltype, subjectcsid, objectcsid, value_type = nil)
      remove_generic(relation_key(reltype, subjectcsid, objectcsid, value_type))
    end

    #####
    # vocabulary term caching
    #####
    def vocab_term_exists?(vocab, term, value_type = nil)
      generic_exists?(vocab_term_key(vocab, term, value_type))
    end

    # rubocop:disable Metrics/ParameterLists
    def put_vocab_term(vocab, term, to_cache, value_type = nil)
      put_generic(vocab_term_key(vocab, term, value_type), to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    def get_vocab_term(vocab, term, value_type = nil)
      get_generic(vocab_term_key(vocab, term, value_type))
    end

    def remove_vocab_term(vocab, term, value_type = nil)
      remove_generic(vocab_term_key(vocab, term, value_type))
    end

    private

    def put_generic(key, to_cache)
      @cache.put(key, to_cache, lifetime: @lifetime)
    end

    def get_generic(key)
      cached_value = @cache.get(key)
      raise(NotFoundError) if @error_if_not_found && !cached_value

      cached_value
    end

    def remove_generic(key)
      @cache.remove(key)
    end

    def generic_exists?(key)
      @cache.exists?(key)
    end

    def set_backend(config)
      if config.key?(:redis)
        Backend::Redis.new(config[:redis])
      elsif config.key?(:store)
        Backend::ActivesupportCacheStore.new(config[:store])
      else
        Backend::Zache.new
      end
    end

    def generate_key(parts = [])
      Digest::SHA2.hexdigest(parts.dup.append(domain).join).prepend("refcache::")
    end

    def object_key(id, value_type = nil)
      generate_key(["collectionobjects", id, value_type].compact)
    end

    def procedure_key(type, id, value_type = nil)
      generate_key([type, id, value_type].compact)
    end

    def relation_key(reltype, subjectcsid, objectcsid, value_type = nil)
      generate_key([reltype, subjectcsid, objectcsid, value_type].compact)
    end

    def term_key(type, subtype, term, value_type = nil)
      generate_key([type, subtype, term, value_type].compact)
    end

    def vocab_term_key(vocab, term, value_type = nil)
      generate_key(["vocabularies", vocab, term, value_type].compact)
    end
  end
end
