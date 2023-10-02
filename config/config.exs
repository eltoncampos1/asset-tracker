import Config

config :asset_tracker, AssetTracker.Ports.Math, adapter: AssetTracker.Adapters.Math.Decimal

config :asset_tracker, AssetTracker.Ports.Repository,
  adapter: AssetTracker.Adapters.Repository.Ets

config :asset_tracker, AssetTracker.Adapters.Repository.Ets, tables: [AssetTracker.Core.Tracker]
