# frozen_string_literal: true

RSpec.describe CollectionSpace::RefCache do
  let(:client) { CollectionSpace::Client.new(CollectionSpace::Configuration.new) }
  let(:domain) { 'core.collectionspace.org' }
  describe 'setup' do
    context 'with valid arguments' do
      let(:cache) { CollectionSpace::RefCache.new(config: { domain: domain }, client: client) }
      it 'can be created' do
        expect { cache }.not_to raise_error
      end
    end

    context 'without a domain' do
      let(:cache) { CollectionSpace::RefCache.new(config: {}, client: client) }
      it 'cannot be created' do
        expect { cache }.to raise_error(KeyError)
      end
    end

    context 'without a client' do
      let(:cache) { CollectionSpace::RefCache.new(config: { domain: domain }, client: {}) }
      it 'cannot be created' do
        expect { cache }.to raise_error(CollectionSpace::RefCache::ClientError)
      end
    end
  end

  describe 'retrieving values' do
    context 'when a value is not present in the cache' do
      let(:parts) { ['placeauthorities', 'place', 'Dark side of the Moon'] }
      context 'with search enabled' do
        let(:cache) do
          CollectionSpace::RefCache.new(config: { domain: domain, search_enabled: true }, client: client)
        end
        let(:cache_raise_error) do
          CollectionSpace::RefCache.new(
            config: { domain: domain, error_if_not_found: true, search_enabled: true }, client: client
          )
        end
        let(:cache_no_delay) do
          CollectionSpace::RefCache.new(
            config: { domain: domain, search_delay: 0, search_enabled: true }, client: client
          )
        end

        it 'will search for a value when the key is not found and fail with nil' do
          allow(cache).to receive(:search).and_return(nil)
          expect(cache.get(*parts)).to be_nil
          expect(cache).to have_received(:search).with(*parts)
        end

        it 'will search for a value when the key is not found and fail with error' do
          allow(cache_raise_error).to receive(:search).and_return(nil)
          expect { cache_raise_error.get(*parts) }.to raise_error(CollectionSpace::RefCache::NotFoundError)
          expect(cache_raise_error).to have_received(:search).with(*parts)
        end

        it 'can delay search when a key is not found' do
          allow(cache).to receive(:search).and_return(nil)
          lock = "#{cache.generate_key(parts)}_lock"
          cache.get(*parts)
          expect(cache.delay?(lock)).to be true
          cache.get(*parts)
          expect(cache).to have_received(:search).with(*parts).once
        end

        it 'will not delay search when configured' do
          allow(cache_no_delay).to receive(:search).and_return(nil)
          lock = "#{cache.generate_key(parts)}_lock"
          cache_no_delay.get(*parts)
          expect(cache_no_delay.delay?(lock)).to be false
          cache_no_delay.get(*parts)
          expect(cache_no_delay).to have_received(:search).with(*parts).twice
        end

        it 'will search for a value when the key is not found and succeed' do
          allow(cache).to receive(:search).and_return('$refname')
          expect(cache.get(*parts)).to eq('$refname')
          expect(cache).to have_received(:search).with(*parts)
        end

        it 'will not search for a value when config is overriden to disable search' do
          allow(cache).to receive(:search).and_return(nil)
          expect(cache.get(*parts, search: false)).to be_nil
          expect(cache).not_to have_received(:search).with(*parts)
        end
      end

      context 'without search enabled' do
        let(:cache) { CollectionSpace::RefCache.new(config: { domain: domain }, client: client) }
        it 'does not search for a value when the key is not found' do
          allow(cache).to receive(:search).and_return(nil)
          expect(cache.get(*parts)).to be_nil
          expect(cache).not_to have_received(:search).with(*parts)
        end

        it 'will search for a value when config is overriden to enable search' do
          allow(cache).to receive(:search).and_return('$refname')
          expect(cache.get(*parts, search: true)).to eq('$refname')
          expect(cache).to have_received(:search).with(*parts)
        end
      end
    end

    context 'when a value is present in the cache' do
      let(:cache) { CollectionSpace::RefCache.new(config: { domain: domain }, client: client) }
      let(:lookup_parts) { ['placeauthorities', 'place', 'The Moon'] }
      let(:insert_parts) { ['placeauthorities', 'place', 'The Moon', '$refname'] }

      it 'returns the refname' do
        allow(cache).to receive(:search).and_return(nil)
        expect(cache.put(*insert_parts)).to include(value: '$refname')
        expect(cache.get(*lookup_parts)).to eq(insert_parts.last)
        expect(cache).not_to have_received(:search)
      end
    end
  end
end
