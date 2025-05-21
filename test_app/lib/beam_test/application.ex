defmodule BeamTest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BeamTestWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:beam_test, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BeamTest.PubSub},
      # Start a worker by calling: BeamTest.Worker.start_link(arg)
      # {BeamTest.Worker, arg},
      BeamTest.Counter, # Added our Counter GenServer
      # Start to serve requests, typically the last entry
      BeamTestWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BeamTest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BeamTestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
