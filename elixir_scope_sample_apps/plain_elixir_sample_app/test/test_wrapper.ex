defmodule ElixirSampleApp.TestWrapper do
  @moduledoc """
  Test helper functions for working with ElixirScope in tests.
  
  This module provides functions to help test GenServer modules
  that use ElixirScope.StateRecorder.
  """
  
  alias ElixirScope.StateRecorder
  
  @doc """
  Stores a GenServer state change event for testing.
  """
  def store_state_change(pid, module, state) do
    StateRecorder.store_event_sync(:state, %{
      pid: pid,
      module: module,
      state: state,
      timestamp: System.monotonic_time()
    })
  end
  
  @doc """
  Stores a GenServer call event for testing.
  """
  def store_call_event(pid, module, message, response, state) do
    StateRecorder.store_event_sync(:genserver, %{
      pid: pid,
      module: module,
      callback: :handle_call,
      message: message,
      response: response,
      state: state,
      timestamp: System.monotonic_time()
    })
  end
  
  @doc """
  Stores a GenServer cast event for testing.
  """
  def store_cast_event(pid, module, message, state) do
    StateRecorder.store_event_sync(:genserver, %{
      pid: pid,
      module: module,
      callback: :handle_cast,
      message: message,
      state: state,
      timestamp: System.monotonic_time()
    })
  end
  
  @doc """
  Stores a GenServer info event for testing.
  """
  def store_info_event(pid, module, message, state) do
    StateRecorder.store_event_sync(:genserver, %{
      pid: pid,
      module: module,
      callback: :handle_info,
      message: message,
      state: state,
      timestamp: System.monotonic_time()
    })
  end
end 