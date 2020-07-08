# frozen_string_literal: true

require 'cgi'

module CollectionSpace
  class RefCache
    # CollectionSpace::RefCache::Search
    module Search
      def search(type, subtype, value)
        service = @client.service(type: type, subtype: subtype)
        field = @search_identifiers ? service[:identifier] : service[:term]
        response = @client.find(
          type: type, subtype: subtype, value: value, field: field
        )
        return ClientError, response.parsed unless response.result.success?

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
