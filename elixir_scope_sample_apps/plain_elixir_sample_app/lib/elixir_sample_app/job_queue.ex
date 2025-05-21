defmodule ElixirSampleApp.JobQueue do
  @moduledoc """
  A job queue that distributes jobs to workers.
  """
  use GenServer
  use ElixirScope.StateRecorder
  
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Add a job to the queue.
  """
  def add_job(job) do
    GenServer.cast(__MODULE__, {:add_job, job})
  end

  @doc """
  Add multiple jobs to the queue.
  """
  def add_jobs(jobs) do
    GenServer.cast(__MODULE__, {:add_jobs, jobs})
  end

  @doc """
  Get queue stats.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # Server callbacks

  @impl true
  def init(_) do
    # Schedule first job processing
    schedule_processing()
    
    state = %{
      pending_jobs: [],
      processed_jobs: 0,
      failed_jobs: 0,
      started_at: DateTime.utc_now()
    }
    
    {:ok, state}
  end

  @impl true
  def handle_cast({:add_job, job}, state) do
    Logger.info("Adding job to queue: #{inspect(job)}")
    
    # Add job to pending list
    new_state = %{state | pending_jobs: state.pending_jobs ++ [job]}
    
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:add_jobs, jobs}, state) do
    Logger.info("Adding #{length(jobs)} jobs to queue")
    
    # Add jobs to pending list
    new_state = %{state | pending_jobs: state.pending_jobs ++ jobs}
    
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    stats = %{
      pending_jobs: length(state.pending_jobs),
      processed_jobs: state.processed_jobs,
      failed_jobs: state.failed_jobs,
      uptime_seconds: DateTime.diff(DateTime.utc_now(), state.started_at)
    }
    
    {:reply, stats, state}
  end

  @impl true
  def handle_info(:process_jobs, state) do
    new_state = process_pending_jobs(state)
    
    # Schedule next processing
    schedule_processing()
    
    {:noreply, new_state}
  end

  # Helper functions

  defp process_pending_jobs(state) do
    case state.pending_jobs do
      [] ->
        # No jobs to process
        state
        
      [job | remaining_jobs] ->
        # Get a random job type
        job_type = Map.get(job, :type, :default)
        
        # Try to find a worker of that type
        workers = ElixirSampleApp.WorkerSupervisor.list_workers()
        available_workers = Enum.filter(workers, fn %{id: id} -> 
          case worker_status(id) do
            %{status: :idle, job_type: worker_job_type} -> worker_job_type == job_type
            _ -> false
          end
        end)
        
        case available_workers do
          [] ->
            # No available workers, create a new one
            worker_name = "worker_#{System.unique_integer([:positive])}"
            {:ok, _pid} = ElixirSampleApp.WorkerSupervisor.start_worker(worker_name, job_type)
            
            # Process the job
            worker = {:via, Registry, {ElixirSampleApp.WorkerRegistry, worker_name}}
            ElixirSampleApp.Worker.process_job(worker, job)
            
          [%{id: worker_id} | _] ->
            # Use an existing worker
            worker = {:via, Registry, {ElixirSampleApp.WorkerRegistry, worker_id}}
            ElixirSampleApp.Worker.process_job(worker, job)
        end
        
        # Update state
        %{state | 
          pending_jobs: remaining_jobs,
          processed_jobs: state.processed_jobs + 1
        }
    end
  end

  defp worker_status(worker_name) do
    worker = {:via, Registry, {ElixirSampleApp.WorkerRegistry, worker_name}}
    
    try do
      ElixirSampleApp.Worker.status(worker)
    catch
      _, _ -> %{status: :error}
    end
  end

  defp schedule_processing do
    # Schedule job processing every 500ms
    Process.send_after(self(), :process_jobs, 500)
  end
end 