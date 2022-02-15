# frozen_string_literal: true

RSpec.describe CollectionSpace::RefCache do
  let(:cache) { CollectionSpace::RefCache.new(config: { domain: domain }) }
  let(:domain) { 'core.collectionspace.org' }
  
  describe 'setup' do
    context 'with valid arguments' do
      it 'can be created' do
        expect { cache }.not_to raise_error
      end
    end

    context 'without a domain' do
      let(:cache) { CollectionSpace::RefCache.new(config: {}) }
      it 'cannot be created' do
        expect { cache }.to raise_error(KeyError)
      end
    end
  end

  describe '#get' do
    context 'when a value is not present in the cache' do
      let(:parts) { ['placeauthorities', 'place', 'Dark side of the Moon'] }

      it 'returns nil' do
        expect(cache.get(*parts)).to be_nil
      end
    end

    context 'when a value is present in the cache' do
      let(:insert_parts) { ['placeauthorities', 'place', 'The Moon', '$refname'] }
      let(:lookup_parts) { ['placeauthorities', 'place', 'The Moon'] }

      it 'returns the refname' do
        cache.put(*insert_parts)
        expect(cache.get(*lookup_parts)).to eq(insert_parts.last)
      end
    end
  end
end
