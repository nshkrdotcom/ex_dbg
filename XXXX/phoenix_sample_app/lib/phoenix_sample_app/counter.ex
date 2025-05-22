defmodule PhoenixSampleApp.Counter do
  @moduledoc """
  A simple counter GenServer that demonstrates ElixirScope's state tracking.
  """
  use GenServer
  use ElixirScope.StateRecorder  # Add ElixirScope.StateRecorder

  @doc """
  Starts the counter with an initial value.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  @doc """
  Gets the current counter value.
  """
  def get() do
    GenServer.call(__MODULE__, :get)
  end

  @doc """
  Increments the counter.
  """
  def increment(amount \\ 1) do
    GenServer.cast(__MODULE__, {:increment, amount})
  end

  @doc """
  Decrements the counter.
  """
  def decrement(amount \\ 1) do
    GenServer.cast(__MODULE__, {:decrement, amount})
  end

  @doc """
  Resets the counter to zero or a specified value.
  """
  def reset(value \\ 0) do
    GenServer.cast(__MODULE__, {:reset, value})
  end

  @doc """
  Updates the counter to a specific value.
  """
  def set(value) do
    GenServer.call(__MODULE__, {:set, value})
  end

  # GenServer Callbacks

  @impl true
  def init(initial_count) do
    {:ok, initial_count}
  end

  @impl true
  def handle_call(:get, _from, count) do
    {:reply, count, count}
  end

  @impl true
  def handle_call({:set, value}, _from, _count) do
    {:reply, value, value}
  end

  @impl true
  def handle_cast({:increment, amount}, count) do
    {:noreply, count + amount}
  end

  @impl true
  def handle_cast({:decrement, amount}, count) do
    {:noreply, count - amount}
  end

  @impl true
  def handle_cast({:reset, value}, _count) do
    {:noreply, value}
  end
end 