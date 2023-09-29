defmodule AssetTracker.Core.AssetTrackerTest do
  use ExUnit.Case

  alias AssetTracker.Core.AssetTracker

  test "new/0" do
    assert %AssetTracker{purchases: %{}, sales: %{}} = AssetTracker.new()
  end
end
