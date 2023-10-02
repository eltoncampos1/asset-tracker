defmodule AssetTracker.Core.TrackerTest do
  use ExUnit.Case

  alias AssetTracker.Core.Tracker
  alias AssetTracker.Core.Asset

  alias AssetTracker.Ports.Math

  describe "Core Asset Tracker" do
    setup do
      {:ok, tracker} = Tracker.new()
      %{tracker: tracker}
    end

    test "new/0" do
      assert {:ok, %Tracker{purchases: %{}, sales: %{}, id: _}} = Tracker.new()
    end

    test "add_purchase/5", %{tracker: tracker} do
      date = Date.utc_today()

      assert %AssetTracker.Core.Tracker{
        id: _,
        purchases: %{
          "GOOGL" =>
            {[
               %AssetTracker.Core.Asset{
                 id: _,
                 asset_symbol: "GOOGL",
                 operation_date: ^date,
                 quantity: 10,
                 unit_price: price,
                 operation_type: :purchase
               }
             ], []}
        },
        sales: %{}
      } =
        Tracker.add_purchase(tracker, "GOOGL", date, 10, 19)

      assert ^price = 19
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

    test "add_sale/5", %{tracker: tracker} do
      symbol = "GOOGL"
      price_first = 5
      price_second = 10
      sold = 12

      assert {%AssetTracker.Core.Tracker{
                id: _,
                purchases: %{
                  "GOOGL" =>
                    {[
                       %AssetTracker.Core.Asset{
                         id: _,
                         asset_symbol: "GOOGL",
                         operation_date: _,
                         quantity: 5,
                         unit_price: ^price_first,
                         operation_type: :purchase
                       }
                     ],
                     [
                       %AssetTracker.Core.Asset{
                         id: _,
                         asset_symbol: "GOOGL",
                         operation_date: _,
                         quantity: 10,
                         unit_price: ^price_second,
                         operation_type: :purchase
                       }
                     ]}
                },
                sales: %{
                  "GOOGL" =>
                    {[
                       %AssetTracker.Core.Asset{
                         id: _,
                         asset_symbol: "GOOGL",
                         operation_date: _,
                         quantity: 5,
                         unit_price: 12,
                         operation_type: :sale
                       }
                     ], []}
                }
              },
              gain_or_loss} =
               tracker
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 10, price_first)
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 10, price_second)
               |> Tracker.add_sale(symbol, Date.utc_today(), 5, sold)

      purchase = Math.mult(price_first, 5)
      paid = Math.mult(sold, 5)
      assert gain_or_loss == Math.sub(paid, purchase)
    end

    test "Always update inventory based on FIFO", %{tracker: tracker} do
      first = 10
      second = 20
      symbol = "GOOGL"

      tracker =
        tracker
        |> Tracker.add_purchase(symbol, Date.utc_today(), first, 10)
        |> Tracker.add_purchase(symbol, Date.utc_today(), second, 11)

      assets = Tracker.get_assets_by_symbol(tracker.purchases, symbol)

      assert {_tail, [%Asset{quantity: ^first}]} = assets

      {tracker, _} =
        tracker
        |> Tracker.add_sale(symbol, Date.utc_today(), 10, 5)

      assets = Tracker.get_assets_by_symbol(tracker.purchases, symbol)

      assert {[%{quantity: ^second}], []} = assets
    end

    test "returns error on sale if total invetory is less than sale qty", %{tracker: tracker} do
      assert {:error, :insuficient_assets} =
               tracker
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 5, 1000)
               |> Tracker.add_sale("GOOGL", Date.utc_today(), 15, 2000)
    end

    test "returns error on sale if does not have the asset on inventory", %{tracker: tracker} do
      assert {:error, :nor_found} =
               tracker
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 5, 1000)
               |> Tracker.add_sale("APPL", Date.utc_today(), 15, 2000)
    end

    test "calculate unrealized gain or loss for sales and purchases", %{tracker: tracker} do
      symbol = "APPL"

      tracker =
        tracker
        |> Tracker.add_purchase(symbol, Date.utc_today(), 10, 10)
        |> Tracker.add_purchase(symbol, Date.utc_today(), 12, 11)

      {tracker, _} =
        tracker
        |> Tracker.add_sale(symbol, Date.utc_today(), 6, 10)

      assert %{purchases: p, sales: s} = Tracker.unrealized_gain_or_loss(tracker, symbol, 15)

      assert p == Math.new(p)
      assert s == Math.new(s)
    end

    test "returns error if no has no asset in inventory on unrealized_gain_or_loss call", %{
      tracker: tracker
    } do
      assert %{purchases: :not_found, sales: :not_found} =
               Tracker.unrealized_gain_or_loss(tracker, "ADDR", 15)
    end
  end
end
