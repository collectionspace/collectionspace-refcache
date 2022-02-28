# frozen_string_literal: true

require 'digest'

module CollectionSpace
  class RefCache
    class NotFoundError < StandardError; end

    attr_reader :config, :domain

    def initialize(config: {})
      @config = config
      @cache = backend(config.fetch(:redis, nil))
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
    def exists?(type, subtype, value)
      generic_exists?(term_key(type, subtype, value))
    end

    # cache.put('placeauthorities', 'place', 'The Moon', $refname)
    # rubocop:disable Metrics/ParameterLists
    def put(type, subtype, value, to_cache)
      put_generic(term_key(type, subtype, value), to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    # cache.get('placeauthorities', 'place', 'The Moon')
    # cache.get('vocabularies', 'languages', 'English')
    def get(type, subtype, value)
      get_generic(term_key(type, subtype, value))
    end

    def remove(type, subtype, value)
      remove_generic(term_key(type, subtype, value))
    end

    #####
    # object caching
    #####
    def put_object(id, to_cache)
      put_generic(object_key(id), to_cache)
    end
    
    def get_object(id)
      get_generic(object_key(id))
    end

    def remove_object(id)
      remove_generic(object_key(id))
    end

    def object_exists?(id)
      generic_exists?(object_key(id))
    end

    #####
    # procedure caching
    #####
    def put_procedure(type, id, to_cache)
      put_generic(procedure_key(type, id), to_cache)
    end

    def get_procedure(type, id)
      get_generic(procedure_key(type, id))
    end

    def remove_procedure(type, id)
      remove_generic(procedure_key(type, id))
    end

    def procedure_exists?(type, id)
      generic_exists?(procedure_key(type, id))
    end

    #####
    # authority term caching
    #####
    def auth_term_exists?(type, subtype, term)
      generic_exists?(term_key(type, subtype, term))
    end

    # rubocop:disable Metrics/ParameterLists
    def put_auth_term(type, subtype, term, to_cache)
      put_generic(term_key(type, subtype, term), to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    def get_auth_term(type, subtype, term)
      get_generic(term_key(type, subtype, term))
    end

    def remove_auth_term(type, subtype, term)
      remove_generic(term_key(type, subtype, term))
    end

    #####
    # relation caching
    #####
    def relation_exists?(reltype, subjectcsid, objectcsid)
      generic_exists?(term_key(reltype, subjectcsid, objectcsid))
    end

    # rubocop:disable Metrics/ParameterLists
    def put_relation(reltype, subjectcsid, objectcsid, to_cache)
      put_generic(term_key(reltype, subjectcsid, objectcsid), to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    def get_relation(reltype, subjectcsid, objectcsid)
      get_generic(term_key(reltype, subjectcsid, objectcsid))
    end

    def remove_relation(reltype, subjectcsid, objectcsid)
      remove_generic(term_key(reltype, subjectcsid, objectcsid))
    end

    #####
    # vocabulary term caching
    #####
    def vocab_term_exists?(vocab, term)
      generic_exists?(vocab_term_key(vocab, term))
    end

    # rubocop:disable Metrics/ParameterLists
    def put_vocab_term(vocab, term, to_cache)
      put_generic(vocab_term_key(vocab, term), to_cache)
    end
    # rubocop:enable Metrics/ParameterLists

    def get_vocab_term(vocab, term)
      get_generic(vocab_term_key(vocab, term))
    end

    def remove_vocab_term(vocab, term)
      remove_generic(vocab_term_key(vocab, term))
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

    def backend(connection)
      connection ? Backend::Redis.new(connection) : Backend::Zache.new
    end

    def generate_key(parts = [])
      Digest::SHA2.hexdigest(parts.dup.append(domain).join).prepend('refcache::')
    end

    def object_key(id)
      generate_key(['collectionobjects', id])
    end

    def procedure_key(type, id)
      generate_key([type, id])
    end

    def relation_key(reltype, subjectcsid, objectcsid)
      generate_key([reltype, subjectcsid, objectcsid])
    end

    def term_key(type, subtype, term)
      generate_key([type, subtype, term])
    end

    def vocab_term_key(vocab, term)
      generate_key(['vocabularies', vocab, term])
    end
  end
end
