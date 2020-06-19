# frozen_string_literal: true

module CollectionSpace
  class RefCache
    # CollectionSpace::RefCache::Search
    module Search
      TERM_SUFFIX = 'TermGroupList/0/termDisplayName'

      def search(type, subtype, value)
        path = build_path(type, subtype)
        field = @search_identifiers ? 'shortIdentfier' : build_term(type)
        criteria = build_criteria(path, type, field, value)
        response = @client.search(criteria, sortBy: 'collectionspace_core:updatedAt DESC')
        total = response.parsed['abstract_common_list']['totalItems'].to_i
        return nil if total.zero?

        item = total == 1 ? item(response) : item(response).first
        item['refName']
      end

      private

      def build_criteria(path, type, field, value)
        CollectionSpace::Search.new.from_hash(
          {
            path: path,
            type: "#{schema(type)[:ns]}_common",
            field: field,
            expression: "= '#{value}'"
          }
        )
      end

      def build_path(type, subtype)
        "#{type}/urn:cspace:name(#{subtype})/items"
      end

      def build_term(type)
        schema(type)[:term]
      end

      def item(response)
        response.parsed['abstract_common_list']['list_item']
      end

      # rubocop:disable Metrics/MethodLength
      def schema(type)
        {
          'citationauthorities' => { ns: 'citations', term: "citation#{TERM_SUFFIX}" },
          'conceptauthorities' => { ns: 'concepts', term: "concept#{TERM_SUFFIX}" },
          'locationauthorities' => { ns: 'locations', term: "loc#{TERM_SUFFIX}" },
          'materialauthorities' => { ns: 'materials', term: "material#{TERM_SUFFIX}" },
          'orgauthorities' => { ns: 'organizations', term: "org#{TERM_SUFFIX}" },
          'personauthorities' => { ns: 'persons', term: "person#{TERM_SUFFIX}" },
          'placeauthorities' => { ns: 'places', term: "place#{TERM_SUFFIX}" },
          'taxonomyauthority' => { ns: 'taxon', term: "place#{TERM_SUFFIX}" },
          'vocabularies' => { ns: 'vocabularyitems', term: 'displayName' },
          'workauthorities' => { ns: 'works', term: "work#{TERM_SUFFIX}" }
        }.fetch(type)
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
