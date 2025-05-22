defmodule ElixirSampleApp.Worker do
  @moduledoc """
  A worker GenServer that processes jobs.
  
  This module demonstrates how ElixirScope can track state changes and messages.
  """
  use GenServer
  use ElixirScope.StateRecorder  # Add ElixirScope.StateRecorder
  
  require Logger

  # Client API

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    
    if name do
      GenServer.start_link(__MODULE__, opts, name: via_tuple(name))
    else
      GenServer.start_link(__MODULE__, opts)
    end
  end

  @doc """
  Process a job asynchronously.
  """
  def process_job(server, job) do
    GenServer.cast(server, {:process_job, job})
  end

  @doc """
  Process a job synchronously and return the result.
  """
  def process_job_sync(server, job) do
    GenServer.call(server, {:process_job, job})
  end

  @doc """
  Get the current worker status.
  """
  def status(server) do
    GenServer.call(server, :status)
  end

  @doc """
  Stop the worker.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  # Server callbacks

  @impl true
  def init(opts) do
    job_type = Keyword.get(opts, :job_type, :default)
    name = Keyword.get(opts, :name, "anonymous")
    
    state = %{
      name: name,
      job_type: job_type,
      processed_jobs: 0,
      status: :idle,
      started_at: DateTime.utc_now(),
      last_job_at: nil
    }
    
    Logger.info("Worker #{name} started with job type: #{job_type}")
    
    {:ok, state}
  end

  @impl true
  def handle_cast({:process_job, job}, state) do
    Logger.info("Worker #{state.name} processing job asynchronously: #{inspect(job)}")
    
    # Update state to processing
    state = %{state | status: :processing}
    
    # Simulate job processing
    process_time = :rand.uniform(1000)
    Process.sleep(process_time)
    
    # Update state after processing
    state = %{state | 
      processed_jobs: state.processed_jobs + 1,
      status: :idle,
      last_job_at: DateTime.utc_now()
    }
    
    Logger.info("Worker #{state.name} completed job: #{inspect(job)}")
    
    {:noreply, state}
  end

  @impl true
  def handle_call({:process_job, job}, _from, state) do
    Logger.info("Worker #{state.name} processing job synchronously: #{inspect(job)}")
    
    # Update state to processing
    state = %{state | status: :processing}
    
    # Simulate job processing
    process_time = :rand.uniform(1000)
    Process.sleep(process_time)
    
    # Update state after processing
    state = %{state | 
      processed_jobs: state.processed_jobs + 1,
      status: :idle,
      last_job_at: DateTime.utc_now()
    }
    
    result = %{job: job, result: "Processed in #{process_time}ms"}
    Logger.info("Worker #{state.name} completed job with result: #{inspect(result)}")
    
    {:reply, result, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  # Helper functions

  defp via_tuple(name) do
    {:via, Registry, {ElixirSampleApp.WorkerRegistry, name}}
  end
end 