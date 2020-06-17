# frozen_string_literal: true

module CollectionSpace
  class RefCache
    # CollectionSpace::RefCache::Search
    module Search
      def search(_type, _subtype, _value)
        # TODO: lookup refname using client
        nil
      end
    end
  end
end
