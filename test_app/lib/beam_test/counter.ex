defmodule BeamTest.Counter do
  use GenServer
  use BeamMicroscope.StateRecorder

  # Client API
  def start_link(initial_state \ %{count: 0}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def increment(by \ 1) do
    GenServer.call(__MODULE__, {:increment, by})
  end

  def get_count() do
    GenServer.call(__MODULE__, :get_count)
  end

  # Server Callbacks
  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:increment, by}, _from, state) do
    new_count = state.count + by
    {:reply, {:ok, new_count}, %{state | count: new_count}}
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    {:reply, state.count, state}
  end
end
