require 'pathname'
require 'sidekiq'
require 'config'

Sidekiq.configure_server do |config|
  config.redis = { url: Colore::C_.redis_url, namespace: Colore::C_.redis_namespace }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Colore::C_.redis_url, namespace: Colore::C_.redis_namespace }
end

