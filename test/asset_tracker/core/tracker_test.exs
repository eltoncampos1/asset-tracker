defmodule AssetTracker.Core.TrackerTest do
  use ExUnit.Case

  alias AssetTracker.Core.Tracker
  alias AssetTracker.Core.Asset

  alias AssetTracker.Ports.Math

  describe "Core Asset Tracker" do
    setup do
      tracker = Tracker.new()
      %{tracker: tracker}
    end

    test "new/0" do
      assert %Tracker{purchases: %{}, sales: %{}} = Tracker.new()
    end

    test "add_purchase/5", %{tracker: tracker} do
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
                purchases: %{
                  "GOOGL" => [
                    %AssetTracker.Core.Asset{
                      id: _,
                      asset_symbol: "GOOGL",
                      operation_date: _,
                      quantity: first_purchase_quantity_res,
                      unit_price: res_price_first,
                      operation_type: :purchase
                    },
                    %AssetTracker.Core.Asset{
                      id: _,
                      asset_symbol: "GOOGL",
                      operation_date: _,
                      quantity: 10,
                      unit_price: res_price_second,
                      operation_type: :purchase
                    }
                  ]
                },
                sales: %{
                  "GOOGL" => [
                    %AssetTracker.Core.Asset{
                      id: _,
                      asset_symbol: "GOOGL",
                      operation_date: _,
                      quantity: 5,
                      unit_price: res_sold,
                      operation_type: :sale
                    }
                  ]
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

      assert res_price_first == price_first
      assert res_price_second == price_second
      assert res_sold == sold
      assert first_purchase_quantity_res == 10 - 5
    end

    test "Always update inventory based on FIFO", %{tracker: tracker} do
      first = 10
      second = 20
      symbol = "GOOGL"

      tracker =
        tracker
        |> Tracker.add_purchase(symbol, Date.utc_today(), first, 10)
        |> Tracker.add_purchase(symbol, Date.utc_today(), second, 11)

      assets = Map.get(tracker.purchases, symbol)

      assert [%{quantity: ^first}, %{quantity: ^second, id: second_id}] = assets

      {tracker, _} =
        tracker
        |> Tracker.add_sale(symbol, Date.utc_today(), 10, 5)

      assets = Map.get(tracker.purchases, symbol)

      assert [%{quantity: ^second, id: ^second_id}] = assets
    end

    test "returns error on sale if total invetory is less than sale qty", %{tracker: tracker} do
      assert {:error, :insuficient_assets} =
               tracker
               |> Tracker.add_purchase("GOOGL", Date.utc_today(), 5, 1000)
               |> Tracker.add_sale("GOOGL", Date.utc_today(), 15, 2000)
    end

    test "returns error on sale if does not have the asset on inventory", %{tracker: tracker} do
      assert {:error, :not_found} =
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


       {tracker, _}  = tracker
        |> Tracker.add_sale(symbol, Date.utc_today(), 6, 10)

      assert "" = Tracker.unrealized_gain_or_loss(tracker, symbol, 15)
    end
  end
end
