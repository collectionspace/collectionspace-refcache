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
