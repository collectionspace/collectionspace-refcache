# frozen_string_literal: true

RSpec.describe CollectionSpace::RefCache do
  let(:base_config){ { domain: 'core.collectionspace.org' } }
  let(:add_config){ {} }
  let(:config){ base_config.merge(add_config) }
  let(:cache) { CollectionSpace::RefCache.new(config: config) }
  
  describe '#initialize' do
    context 'with valid arguments' do
      it 'can be created' do
        expect { cache }.not_to raise_error
      end
    end

    context 'without a domain' do
      let(:config) { {} }
      it 'cannot be created' do
        expect { cache }.to raise_error(KeyError)
      end
    end
  end

  context 'when zache backend' do
    describe '#initialize' do
      it 'returns Zache cache' do
        c = cache.instance_variable_get(:@cache)
        expect(c).to be_a(CollectionSpace::RefCache::Backend::Zache)
      end
    end

    describe '#clean' do
      let(:add_config){ {lifetime: 0.2} }
      
      it 'removes expired keys from cache' do
        populate_cache(cache)
        sleep(1)
        cache.clean
        expect(cache.size).to eq(0)
      end
    end

    describe '#exists?' do
      it 'returns as expected', :aggregate_failures do
        expect(cache.exists?('a', 'b', 'c')).to be false
        populate_cache(cache)
        expect(cache.exists?('a', 'b', 'c')).to be true
      end
    end

    describe '#get' do
      context 'when key is cached' do
        it 'returns cached value' do
          populate_cache(cache)
          expect(cache.get('a', 'b', 'c')).to eq('d')
        end
      end
      
      context 'when key is not cached' do
        context 'with @error_if_not_found = false' do
          it 'returns nil' do
            expect(cache.get('a', 'b', 'c')).to be nil
          end
        end

        context 'with @error_if_not_found = true' do
          let(:add_config){ { error_if_not_found: true } }

          it 'raises NotFoundError' do
            expect{ cache.get('a', 'b', 'c') }.to raise_error(CollectionSpace::RefCache::NotFoundError)
          end
        end
      end
    end

    describe '#put' do
      it 'adds keys as expected', :aggregate_failures do
        expect(cache.size).to eq(0)
        cache.put('w', 'x', 'y', 'z')
        expect(cache.size).to eq(1)
        expect(cache.exists?('w', 'x', 'y')).to be true
        cache.put('w', 'x', 'y', 'z')
        expect(cache.size).to eq(1)
      end
    end

    describe '#remove' do
      it 'removes given key as expected', :aggregate_failures do
        populate_cache(cache)
        expect(cache.size).to eq(3)
        cache.remove('a', 'b', 'c')
        expect(cache.size).to eq(2)
        expect(cache.exists?('a', 'b', 'c')).to be false
        cache.remove('a', 'b', 'c')
        expect(cache.size).to eq(2)
      end
    end
  end

  context 'when redis backend' do
    let(:add_config){ {redis: 'redis://localhost:6379/1'} }
    
    describe '#initialize' do
      it 'returns Redis cache' do
        c = cache.instance_variable_get(:@cache)
        expect(c).to be_a(CollectionSpace::RefCache::Backend::Redis)
      end
    end
  end
  

  # describe '#get' do
  #   context 'when a value is not present in the cache' do
  #     let(:parts) { ['placeauthorities', 'place', 'Dark side of the Moon'] }

  #     it 'returns nil' do
  #       expect(cache.get(*parts)).to be_nil
  #     end
  #   end

  #   context 'when a value is present in the cache' do
  #     let(:insert_parts) { ['placeauthorities', 'place', 'The Moon', '$refname'] }
  #     let(:lookup_parts) { ['placeauthorities', 'place', 'The Moon'] }

  #     it 'returns the refname' do
  #       cache.put(*insert_parts)
  #       expect(cache.get(*lookup_parts)).to eq(insert_parts.last)
  #     end
  #   end
  # end
end
