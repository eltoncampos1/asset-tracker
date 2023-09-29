defmodule AssetTracker.Core.TrackerTest do
  use ExUnit.Case

  alias AssetTracker.Core.Tracker
  alias AssetTracker.Core.Asset

  describe "Core Asset Tracker" do
    setup do
      tracker = Tracker.new()
      %{tracker: tracker}
    end

    test "new/0" do
      assert %Tracker{purchases: %{}, sales: %{}} = Tracker.new()
    end

    test "add_sale/5", %{tracker: tracker} do
      date = Date.utc_today()

      assert %Tracker{
               purchases: %{
                 "GOOGL" => [
                   %Asset{
                     id: _,
                     asset_symbol: "GOOGL",
                     operation_date: ^date,
                     quantity: 10,
                     unit_price: price,
                     operation_type: :purchase
                   }
                 ]
               },
               sales: %{}
             } = Tracker.add_purchase(tracker, "GOOGL", date, 10, 19)

      assert ^price = Decimal.new("19")
    end

    test "error on add purchases with invalid quantity", %{tracker: tracker} do
      date = Date.utc_today()

      assert {:error, "The quantity and value must be grather than zero"} =
               Tracker.add_purchase(tracker, "GOOGL", date, 0, 19)

      assert {:error, "The quantity and value must be grather than zero"} =
               Tracker.add_purchase(tracker, "GOOGL", date, 0, 19)

      assert {:error, "The quantity and value must be grather than zero"} =
               Tracker.add_purchase(tracker, "GOOGL", date, -1, 19)
    end
  end
end
