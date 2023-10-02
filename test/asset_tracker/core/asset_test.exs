defmodule AssetTracker.Core.AssetTest do
  use ExUnit.Case

  describe "new/5" do
    test "create asset type purchase" do
      assert %AssetTracker.Core.Asset{
               id: _,
               asset_symbol: "APPL",
               operation_date: _,
               quantity: 10,
               unit_price: 10,
               operation_type: :purchase
             } = AssetTracker.Core.Asset.new("APPL", Date.utc_today(), 10, 10, :purchase)
    end

    test "create asset type sale" do
      assert %AssetTracker.Core.Asset{
               id: _,
               asset_symbol: "APPL",
               operation_date: _,
               quantity: 10,
               unit_price: 10,
               operation_type: :sale
             } = AssetTracker.Core.Asset.new("APPL", Date.utc_today(), 10, 10, :sale)
    end
  end
end
