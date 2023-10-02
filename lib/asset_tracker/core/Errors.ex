defmodule AssetTracker.Core.Errors do
  @moduledoc """
  Centralize commom errors
  """
  def not_found, do: {:error, :not_found}
end
