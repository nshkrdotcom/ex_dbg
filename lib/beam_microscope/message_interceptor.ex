defmodule BeamMicroscope.MessageInterceptor do
  use GenServer

  # Client API
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Public function to start tracing messages for all processes
  # or specific ones if enhanced later.
  def setup_tracing() do
    GenServer.call(__MODULE__, :setup_tracing)
  end

  def stop_tracing() do
    GenServer.call(__MODULE__, :stop_tracing)
  end

  # Server Callbacks
  @impl true
  def init(:ok) do
    # The state could track whether tracing is active, and :dbg options.
    {:ok, %{tracing_active: false}}
  end

  @impl true
  def handle_call(:setup_tracing, _from, state) do
    if state.tracing_active do
      {:reply, {:error, :already_tracing}, state}
    else
      # Using :dbg.tracer/2 to set up this GenServer process as the tracer.
      # The {<tracer_module>, <tracer_option>} tuple specifies how tracing happens.
      # Here, we use {__MODULE__, :trace_dispatch} which means a :trace_dispatch
      # function in this module will be called with trace events.
      # However, a simpler way for message passing is to send messages to self().
      :dbg.tracer(:process, {self(), []}) # Send trace messages to this GenServer's mailbox

      # :dbg.p/2 specifies which processes and events to trace.
      # :all means all processes.
      # [:send, :receive] means trace message sending and receiving.
      # Could be changed to :new_processes for less overhead initially.
      :dbg.p(:all, [:send, :receive])

      BeamMicroscope.TraceDB.store_event(:message_tracing_started, %{})
      {:reply, :ok, %{state | tracing_active: true}}
    end
  end

  @impl true
  def handle_call(:stop_tracing, _from, state) do
    if not state.tracing_active do
      {:reply, {:error, :not_tracing}, state}
    else
      :dbg.stop_clear() # Stops all tracing and clears all trace patterns
      BeamMicroscope.TraceDB.store_event(:message_tracing_stopped, %{})
      {:reply, :ok, %{state | tracing_active: false}}
    end
  end

  # Handle trace messages sent from :dbg
  # Format: {:trace, pid, :send | :receive, message_content, receiver_pid_or_name (for send)}
  # Format: {:trace, pid, :receive, message_content}
  @impl true
  def handle_info({:trace, from_pid, :send, message, to_pid_or_name}, state) do
    BeamMicroscope.TraceDB.store_event(:message_sent, %{
      from_pid: from_pid,
      to_pid_or_name: to_pid_or_name, # Could be a registered name or a PID
      message: message
    })
    {:noreply, state}
  end

  @impl true
  def handle_info({:trace, pid, :receive, message, _extra}, state) do # :dbg sometimes adds extra info
    BeamMicroscope.TraceDB.store_event(:message_received, %{
      pid: pid,
      message: message
    })
    {:noreply, state}
  end

  # Catch-all for other messages
  @impl true
  def handle_info(message, state) do
    # Useful for debugging if unexpected messages arrive
    # IO.inspect({__MODULE__, :unhandled_info, message})
    {:noreply, state}
  end
end
