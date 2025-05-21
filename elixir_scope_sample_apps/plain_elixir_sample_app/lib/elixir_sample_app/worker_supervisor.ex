defmodule ElixirSampleApp.WorkerSupervisor do
  @moduledoc """
  Supervisor for worker processes.
  
  This demonstrates how ElixirScope can track supervision relationships.
  """
  use Supervisor

  def start_link(init_arg \\ []) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Start with no children - workers will be added dynamically
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Dynamically starts a worker with the given name and job type.
  """
  def start_worker(name, job_type) do
    child_spec = %{
      id: name,
      start: {ElixirSampleApp.Worker, :start_link, [[name: name, job_type: job_type]]},
      restart: :temporary
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stops a worker with the given name.
  """
  def stop_worker(name) do
    case Registry.lookup(ElixirSampleApp.WorkerRegistry, name) do
      [{pid, _}] -> 
        Supervisor.terminate_child(__MODULE__, name)
        Supervisor.delete_child(__MODULE__, name)
        {:ok, pid}
      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Gets a list of all active workers.
  """
  def list_workers do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {id, pid, type, _} ->
      %{id: id, pid: pid, type: type}
    end)
  end
end 