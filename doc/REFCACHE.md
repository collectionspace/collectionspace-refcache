# Refcache

Setup and usage:

```ruby
# In-memory cache (Zache) will be used as backend if neither :redis nor :store are included
#   in config
cache_config = {
  # redis: 'redis://localhost:6379/1', # optional
  # store: ActiveSupport::Cache::Store or SolidCache::Store object, # optional
  domain: 'core.collectionspace.org',
  error_if_not_found: false, # raise error if key cannot be retrieved (default false)
  lifetime: 5 * 60, # cache expiry in seconds (default is 5 minutes)
}
cache = CollectionSpace::Refcache.new(config: cache_config)
cache.get('placeauthorities', 'place', 'Death Valley') # $refname or error / nil if not found
cache.exists?('placeauthorities', 'place', 'Death Valley') # check for key

# example for vocabs
cache.get('vocabularies', 'languages', 'English') # $refname or error / nil if not found
cache.exists?('vocabularies', 'languages', 'English') # check for key
```

The cache can be pre-populated:

```ruby
items = [
  ['placeauthorities', 'place', 'Mars Colony', '$refname']
].each do |item|
  cache.put(*item)
end
cache.exists?('placeauthorities', 'place', 'Mars Colony') # true
cache.get('placeauthorities', 'place', 'Mars Colony') # '$refname'
```
