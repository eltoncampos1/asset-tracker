defmodule AssetTracker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias AssetTracker.Adapter.Math

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: AssetTracker.Worker.start_link(arg)
      # {AssetTracker.Worker, arg}
      Math.Decimal
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AssetTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
