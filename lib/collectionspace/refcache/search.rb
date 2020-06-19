# frozen_string_literal: true

module CollectionSpace
  class RefCache
    # CollectionSpace::RefCache::Search
    module Search
      def search(type, subtype, value)
        service = CollectionSpace::Service.get(type: type, subtype: subtype)
        field = @search_identifiers ? service[:identifier] : service[:term]
        response = @client.find(type: type, subtype: subtype, value: value, field: field)
        total = response.parsed['abstract_common_list']['totalItems'].to_i
        return nil if total.zero?

        item = total == 1 ? item(response) : item(response).first
        item['refName']
      end

      private

      def item(response)
        response.parsed['abstract_common_list']['list_item']
      end
    end
  end
end
