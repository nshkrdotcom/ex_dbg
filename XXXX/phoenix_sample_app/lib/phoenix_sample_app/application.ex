defmodule PhoenixSampleApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Initialize ElixirScope with Phoenix tracing
    ElixirScope.setup(
      phoenix: true,
      storage: :ets,
      tracing_level: :full,
      sample_rate: 1.0
    )

    children = [
      # Start the Telemetry supervisor
      PhoenixSampleAppWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PhoenixSampleApp.PubSub},
      # Start the Endpoint (http/https)
      PhoenixSampleAppWeb.Endpoint,
      # Start the sample counter server
      PhoenixSampleApp.Counter
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixSampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixSampleAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end 