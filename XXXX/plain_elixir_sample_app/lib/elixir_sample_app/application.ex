defmodule ElixirSampleApp.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    # Initialize ElixirScope
    ElixirScope.setup(
      storage: :ets,
      trace_all: false,
      tracing_level: :full,
      sample_rate: 1.0
    )

    children = [
      # Start the Task Supervisor
      {Task.Supervisor, name: ElixirSampleApp.TaskSupervisor},
      # Start the WorkerRegistry
      {Registry, keys: :unique, name: ElixirSampleApp.WorkerRegistry},
      # Start the WorkerSupervisor
      ElixirSampleApp.WorkerSupervisor,
      # Start the JobQueue
      ElixirSampleApp.JobQueue
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirSampleApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end 