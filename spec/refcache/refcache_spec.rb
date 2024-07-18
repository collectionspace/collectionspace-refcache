# frozen_string_literal: true

require "active_support"
require "mock_redis"

RSpec.describe CollectionSpace::RefCache do
  let(:base_config) { { backend: CollectionSpace::RefCache::Backend::Zache.new, domain: "core.collectionspace.org" } }
  let(:add_config) { {} }
  let(:config) { base_config.merge(add_config) }
  let(:cache) { described_class.new(config: config) }

  describe "#initialize" do
    context "with valid arguments" do
      it "can be created" do
        expect { cache }.not_to(raise_error)
      end
    end

    context "without a domain" do
      let(:config) { {} }

      it "cannot be created" do
        expect { cache }.to raise_error(KeyError)
      end
    end
  end

  # The backends are tested in the context of RefCache's methods because:
  #   - The backend methods are not available in the interface to be called directly (without using
  #     dirty Ruby tricks anyway)
  #   - The RefCache methods are the interface to the backends and it is important that they
  #     work as expected
  context "when zache backend" do
    describe "#initialize" do
      it "returns Zache cache" do
        c = cache.instance_variable_get(:@cache)
        expect(c).to be_a(CollectionSpace::RefCache::Backend::Zache)
      end
    end

    describe "#clean" do
      let(:add_config) { { lifetime: 0.2 } }

      it "removes expired keys from cache" do
        populate_cache(cache)
        sleep(1)
        cache.clean
        expect(cache.size).to eq(0)
      end
    end

    describe "#exists?" do
      it "returns as expected", :aggregate_failures do
        expect(cache.exists?("a", "b", "c")).to be false
        populate_cache(cache)
        expect(cache.exists?("a", "b", "c")).to be true
      end
    end

    describe "#flush" do
      it "clears all keys as expected" do
        populate_cache(cache)
        cache.flush
        expect(cache.size).to eq(0)
      end
    end

    describe "#get" do
      context "when key is cached" do
        it "returns cached value" do
          populate_cache(cache)
          expect(cache.get("a", "b", "c")).to eq("d")
        end
      end

      context "when key is not cached" do
        context "with @error_if_not_found = false" do
          it "returns nil" do
            expect(cache.get("a", "b", "c")).to be nil
          end
        end

        context "with @error_if_not_found = true" do
          let(:add_config) { { error_if_not_found: true } }
          let(:result) { cache.get("a", "b", "c") }

          it "raises NotFoundError" do
            expect { result }.to raise_error(CollectionSpace::RefCache::NotFoundError)
          end
        end
      end
    end

    describe "#put" do
      it "adds keys as expected", :aggregate_failures do
        expect(cache.size).to eq(0)
        cache.put("w", "x", "y", "z")
        expect(cache.size).to eq(1)
        expect(cache.exists?("w", "x", "y")).to be true
        cache.put("w", "x", "y", "z")
        expect(cache.size).to eq(1)
      end
    end

    describe "#remove" do
      it "removes given key as expected", :aggregate_failures do
        populate_cache(cache)
        expect(cache.size).to eq(3)
        cache.remove("a", "b", "c")
        expect(cache.size).to eq(2)
        expect(cache.exists?("a", "b", "c")).to be false
        cache.remove("a", "b", "c")
        expect(cache.size).to eq(2)
      end
    end
  end

  context "when redis backend" do
    before do
      redis = MockRedis.new
      allow(Redis).to receive(:new).and_return(redis)
    end

    let(:redis_config) { { backend: CollectionSpace::RefCache::Backend::Redis.new("redis://localhost:6379/1") } }
    let(:add_config) { {} }
    let(:config) { base_config.merge(redis_config).merge(add_config) }

    describe "#initialize" do
      it "returns Redis cache" do
        c = cache.instance_variable_get(:@cache)
        expect(c).to be_a(CollectionSpace::RefCache::Backend::Redis)
      end
    end

    describe "#clean" do
      let(:add_config) { { lifetime: 0.2 } }

      it "removes expired keys from cache" do
        populate_cache(cache)
        sleep(1)
        expect(cache.size).to eq(0)
      end
    end

    describe "#exists?" do
      it "returns as expected", :aggregate_failures do
        expect(cache.exists?("a", "b", "c")).to be false
        populate_cache(cache)
        expect(cache.exists?("a", "b", "c")).to be true
      end
    end

    describe "#flush" do
      it "clears all keys as expected" do
        populate_cache(cache)
        cache.flush
        expect(cache.size).to eq(0)
      end
    end

    describe "#get" do
      context "when key is cached" do
        it "returns cached value" do
          populate_cache(cache)
          expect(cache.get("a", "b", "c")).to eq("d")
        end
      end

      context "when key is not cached" do
        context "with @error_if_not_found = false" do
          it "returns nil" do
            expect(cache.get("a", "b", "c")).to be nil
          end
        end

        context "with @error_if_not_found = true" do
          let(:add_config) { { error_if_not_found: true } }
          let(:result) { cache.get("a", "b", "c") }

          it "raises NotFoundError" do
            expect { result }.to raise_error(CollectionSpace::RefCache::NotFoundError)
          end
        end
      end
    end

    describe "#put" do
      it "adds keys as expected", :aggregate_failures do
        expect(cache.size).to eq(0)
        cache.put("w", "x", "y", "z")
        expect(cache.size).to eq(1)
        expect(cache.exists?("w", "x", "y")).to be true
        cache.put("w", "x", "y", "z")
        expect(cache.size).to eq(1)
      end
    end

    describe "#remove" do
      it "removes given key as expected", :aggregate_failures do
        populate_cache(cache)
        expect(cache.size).to eq(3)
        cache.remove("a", "b", "c")
        expect(cache.size).to eq(2)
        expect(cache.exists?("a", "b", "c")).to be false
        cache.remove("a", "b", "c")
        expect(cache.size).to eq(2)
      end
    end
  end

  context "when rails backend" do
    before do
      @rails_cache = ActiveSupport::Cache::MemoryStore.new
    end

    let(:rails_config) { { backend: CollectionSpace::RefCache::Backend::Rails.new(@rails_cache) } }
    let(:add_config) { {} }
    let(:config) { base_config.merge(rails_config).merge(add_config) }

    describe "#initialize" do
      it "returns Rails cache" do
        c = cache.instance_variable_get(:@cache)
        expect(c).to be_a(CollectionSpace::RefCache::Backend::Rails)
      end
    end

    describe "#clean" do
      let(:add_config) { { lifetime: 0.2 } }

      it "removes expired keys from cache" do
        populate_cache(cache)
        sleep(1)
        expect(cache.exists?("a", "b", "c")).to be false
      end
    end

    describe "#exists?" do
      it "returns as expected", :aggregate_failures do
        expect(cache.exists?("a", "b", "c")).to be false
        populate_cache(cache)
        expect(cache.exists?("a", "b", "c")).to be true
      end
    end

    describe "#flush" do
      it "clears all keys as expected" do
        populate_cache(cache)
        cache.flush
        expect(cache.exists?("a", "b", "c")).to be false
      end
    end

    describe "#get" do
      context "when key is cached" do
        it "returns cached value" do
          populate_cache(cache)
          expect(cache.get("a", "b", "c")).to eq("d")
        end
      end

      context "when key is not cached" do
        context "with @error_if_not_found = false" do
          it "returns nil" do
            expect(cache.get("a", "b", "c")).to be nil
          end
        end

        context "with @error_if_not_found = true" do
          let(:add_config) { { error_if_not_found: true } }
          let(:result) { cache.get("a", "b", "c") }

          it "raises NotFoundError" do
            expect { result }.to raise_error(CollectionSpace::RefCache::NotFoundError)
          end
        end
      end
    end

    describe "#put" do
      it "adds keys as expected", :aggregate_failures do
        cache.put("w", "x", "y", "z")
        expect(cache.exists?("w", "x", "y")).to be true
      end
    end

    describe "#remove" do
      it "removes given key as expected", :aggregate_failures do
        populate_cache(cache)
        expect(cache.exists?("a", "b", "c")).to be true
        cache.remove("a", "b", "c")
        expect(cache.exists?("a", "b", "c")).to be false
      end
    end
  end

  describe "put, get and remove object" do
    it "manipulates entries for objects in cache as expected", :aggregate_failures do
      expect(cache.size).to eq(0)
      cache.put_object("foo", "bar")
      expect(cache.size).to eq(1)
      expect(cache.object_exists?("foo")).to be true
      expect(cache.get_object("foo")).to eq("bar")
      cache.remove_object("foo")
      expect(cache.size).to eq(0)
    end
  end

  describe "put, get and remove procedure" do
    it "manipulates entries for procedures in cache as expected", :aggregate_failures do
      expect(cache.size).to eq(0)
      cache.put_procedure("foo", "bar", "baz")
      expect(cache.size).to eq(1)
      expect(cache.procedure_exists?("foo", "bar")).to be true
      expect(cache.get_procedure("foo", "bar")).to eq("baz")
      cache.remove_procedure("foo", "bar")
      expect(cache.size).to eq(0)
    end
  end

  describe "put, get and remove auth term" do
    it "manipulates entries for authority terms in cache as expected", :aggregate_failures do
      expect(cache.size).to eq(0)
      cache.put_auth_term("foo", "bar", "bam", "baz")
      expect(cache.size).to eq(1)
      expect(cache.auth_term_exists?("foo", "bar", "bam")).to be true
      expect(cache.get_auth_term("foo", "bar", "bam")).to eq("baz")
      cache.remove_auth_term("foo", "bar", "bam")
      expect(cache.size).to eq(0)
    end
  end

  describe "put, get and remove relation" do
    it "manipulates entries for relations in cache as expected", :aggregate_failures do
      expect(cache.size).to eq(0)
      cache.put_relation("foo", "bar", "bam", "baz")
      expect(cache.size).to eq(1)
      expect(cache.relation_exists?("foo", "bar", "bam")).to be true
      expect(cache.get_relation("foo", "bar", "bam")).to eq("baz")
      cache.remove_relation("foo", "bar", "bam")
      expect(cache.size).to eq(0)
    end
  end

  describe "put, get and remove vocab term" do
    it "manipulates entries for vocabulary terms in cache as expected", :aggregate_failures do
      expect(cache.size).to eq(0)
      cache.put_vocab_term("foo", "bar", "baz")
      expect(cache.size).to eq(1)
      expect(cache.vocab_term_exists?("foo", "bar")).to be true
      expect(cache.get_vocab_term("foo", "bar")).to eq("baz")
      cache.remove_vocab_term("foo", "bar")
      expect(cache.size).to eq(0)
    end
  end
end
