defmodule BeamMicroscope.QueryEngine do
  @moduledoc """
  Provides functions to query and display trace data from BeamMicroscope.TraceDB.
  """

  alias BeamMicroscope.TraceDB

  @doc """
  Retrieves all events from TraceDB and prints them to the console in a readable format.
  Events are expected to be {id, event_map}, where event_map contains :timestamp, :type, and :data.
  """
  def display_full_timeline() do
    IO.puts("\n--- Full Event Timeline ---")
    case TraceDB.get_all_events() do
      [] ->
        IO.puts("No events recorded.")
      events ->
        # events is a list of {unique_id, event_record}
        # event_record is %{id: unique_id, timestamp: ts, type: type, data: data}
        # Already sorted by unique_id (which is also time-ordered due to :monotonic option)
        Enum.each(events, fn {_id, event} ->
          IO.puts("[\#{format_timestamp(event.timestamp)}] [ID: \#{event.id}] [\#{event.type}]")
          print_event_data(event.data, "  ")
          IO.puts("---")
        end)
    end
    :ok
  end

  @doc """
  Retrieves and displays state change events for a specific PID.
  Filters events from TraceDB for :genserver_state_pre_call and :genserver_state_post_call.
  """
  def display_state_history_for_pid(pid) when is_pid(pid) do
    IO.puts("\n--- State History for PID: \#{inspect(pid)} ---")
    case TraceDB.get_all_events() do
      [] ->
        IO.puts("No events recorded.")
      all_events ->
        state_events =
          Enum.filter(all_events, fn {_id, event} ->
            event.data[:pid] == pid &&
              (event.type == :genserver_state_pre_call || event.type == :genserver_state_post_call)
          end)

        if Enum.empty?(state_events) do
          IO.puts("No state events recorded for this PID.")
        else
          Enum.each(state_events, fn {_id, event} ->
            IO.puts("[\#{format_timestamp(event.timestamp)}] [ID: \#{event.id}] [\#{event.type}]")
            print_event_data(event.data, "  ")
            IO.puts("---")
          end)
        end
    end
    :ok
  end

  defp print_event_data(data, prefix \ "") when is_map(data) do
    data
    |> Enum.sort_by(fn {key, _val} -> key end) # Sort by key for consistent output
    |> Enum.each(fn {key, value} ->
      # Special handling for potentially large :state_before, :state_after, :message
      cond do
        key in [:state_before, :state_after, :message, :original_result] ->
          IO.puts("\#{prefix}\#{key}: \#{inspect(value, limit: :infinity, pretty: true)}") # Pretty print maps/structs
        true ->
          IO.puts("\#{prefix}\#{key}: \#{inspect(value)}")
      end
    end)
  end
  defp print_event_data(other, prefix \ "") do
    IO.puts("\#{prefix}Data: \#{inspect(other)}")
  end

  # Helper to format monotonic time. This is a simple version.
  # For real applications, you might want to convert to system time if a start reference is kept.
  defp format_timestamp(monotonic_time_int) do
    # Shows time in milliseconds from some arbitrary start point (e.g., application start)
    # For more human-readable time, you'd need to correlate with System.system_time/1
    # at the start of tracing or convert, but for a timeline, relative monotonic is fine.
    "TS_MONO:\#{monotonic_time_int}"
  end
end
