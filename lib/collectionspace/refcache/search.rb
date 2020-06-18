# frozen_string_literal: true

module CollectionSpace
  class RefCache
    # CollectionSpace::RefCache::Search
    module Search
      def search(type, subtype, value)
        path = build_path(type, subtype)
        field = @search_identifiers ? 'shortIdentfier' : build_term(type)
        criteria = build_criteria(path, type, field, value)
        response = @client.search(criteria) # { 'sortBy' => 'collectionspace_core:updatedAt' }
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
        "#{schema(type)[:term]}TermGroupList/0/termDisplayName"
      end

      def item(response)
        response.parsed['abstract_common_list']['list_item']
      end

      def schema(type)
        {
          'personauthorities' => { ns: 'persons', term: 'person' },
          'placeauthorities' => { ns: 'places', term: 'place' }
        }.fetch(type)
      end
    end
  end
end
