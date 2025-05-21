defmodule BeamMicroscope.ProcessObserver do
  use GenServer

  # Client API
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Public function to start monitoring a specific PID
  def observe(pid, metadata \\ %{}) when is_pid(pid) do
    GenServer.cast(__MODULE__, {:observe_pid, pid, metadata})
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    # No specific state needed for now, could hold observed PIDs if desired
    {:ok, %{observed_pids: Map.new()}}
  end

  @impl true
  def handle_cast({:observe_pid, pid, metadata}, state) do
    if Map.has_key?(state.observed_pids, pid) do
      {:noreply, state} # Already observing
    else
      # Monitor the process. The ProcessObserver GenServer will receive a :DOWN message if it exits.
      ref = Process.monitor(pid)
      BeamMicroscope.TraceDB.store_event(:process_observed, %{
        pid: pid,
        ref: ref,
        metadata: metadata,
        status: :started
      })
      new_observed_pids = Map.put(state.observed_pids, pid, ref)
      {:noreply, %{state | observed_pids: new_observed_pids}}
    end
  end

  # This callback handles the :DOWN messages from monitored processes
  @impl true
  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    # Process has gone down
    BeamMicroscope.TraceDB.store_event(:process_down, %{
      pid: pid,
      ref: ref,
      reason: reason
    })
    # Optional: Remove from observed_pids map if desired
    new_observed_pids = Map.delete(state.observed_pids, pid)
    {:noreply, %{state | observed_pids: new_observed_pids}}
  end

  # Catch-all for other messages
  @impl true
  def handle_info(message, state) do
    # Useful for debugging if unexpected messages arrive
    # IO.inspect({__MODULE__, :unhandled_info, message})
    {:noreply, state}
  end
end
