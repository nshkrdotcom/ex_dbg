defmodule BeamMicroscope.TraceDB do
  use GenServer

  @table_name :beam_microscope_events

  # Client API

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def store_event(event_type, data) do
    GenServer.cast(__MODULE__, {:store_event, event_type, data})
  end

  def get_all_events do
    GenServer.call(__MODULE__, :get_all_events)
  end

  # Server Callbacks

  @impl true
  def init(:ok) do
    # Ensure ETS table is public so it can be read directly if needed,
    # but primarily accessed via this GenServer.
    # :ordered_set allows for chronological retrieval if IDs are sortable (like timestamps or unique integers).
    @table_name = :ets.new(@table_name, [:ordered_set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:store_event, event_type, data}, state) do
    timestamp = System.monotonic_time() # Using monotonic_time for ordering
    unique_id = System.unique_integer([:positive, :monotonic])

    event_record = %{
      id: unique_id,
      timestamp: timestamp,
      type: event_type,
      data: data
    }

    :ets.insert(@table_name, {unique_id, event_record})
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_all_events, _from, state) do
    # Returns a list of events, ordered by insertion (due to unique_id and :ordered_set)
    events = :ets.tab2list(@table_name)
    {:reply, events, state}
  end
end
