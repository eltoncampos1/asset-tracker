defmodule AssetTracker.Tracker.Repository do
  alias AssetTracker.Core.Tracker
  alias AssetTracker.Ports.Repository

  def insert(params) do
    Tracker
    |> Repository.insert(params)
  end

  def update(id, params) do
    Tracker
    |> Repository.update(id, params)
  end
end
