defmodule AssetTracker.Core.TrackerTest do
  use ExUnit.Case

  alias AssetTracker.Core.Tracker

  describe "Core Asset Tracker" do
    setup do
      tracker = Tracker.new()
      %{tracker: tracker}
    end

    test "new/0" do
      assert %Tracker{purchases: %{}, sales: %{}} = Tracker.new()
    end
  end
end
