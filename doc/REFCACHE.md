# RefCache

Setup and usage:

```ruby
client = CollectionSpace::Client.new(
  CollectionSpace::Configuration.new(
    base_uri: 'https://core.dev.collectionspace.org/cspace-services',
    username: 'admin@core.collectionspace.org',
    password: 'Administrator'
  )
)
cache_config = {
  domain: 'core.collectionspace.org',
  error_if_not_found: false, # raise error if key cannot be retrieved (default false)
  lifetime: 5 * 60, # cache expiry in seconds (default is 5 minutes)
  search_enabled: true # use client to search for refname if not in cache
}
cache = CollectionSpace::RefCache.new(config: cache_config, client: client)
cache.get('placeauthorities', 'place', 'Death Valley') # $refname or error / nil if not found
cache.exists?('placeauthorities', 'place', 'Death Valley') # check for key
```

The cache can be pre-populated:

```ruby
items = [
  ['placeauthorities', 'place', 'Death Valley', '$refname']
].each do |item|
  cache.put(*item)
end
cache.exists?('placeauthorities', 'place', 'Death Valley') # true
cache.get('placeauthorities', 'place', 'Death Valley') # '$refname'
```
