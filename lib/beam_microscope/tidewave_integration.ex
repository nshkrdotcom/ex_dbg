defmodule BeamMicroscope.TidewaveIntegration do
  @moduledoc """
  Provides functionality to integrate BeamMicroscope with Tidewave.
  Allows BeamMicroscope's query capabilities to be exposed as tools to a Tidewave agent.
  """

  alias BeamMicroscope.QueryEngine # Remains from previous versions, for context or future use

  @doc """
  Checks if Tidewave is available and registers BeamMicroscope tools.

  This function should be called once, perhaps during application startup
  or manually when Tidewave integration is desired.
  """
  def setup_tidewave_tools() do
    if Code.ensure_loaded?(Tidewave) do # Check as per current prompt
      IO.puts("[BeamMicroscope.TidewaveIntegration] Tidewave found. Registering tools...")

      # Tool 1: Get the full event timeline (simplified for Tidewave)
      Tidewave.Plugin.register_tool(%{
        name: "beam_microscope_get_full_timeline",
        description: "Retrieves a summary of all recorded trace events from BEAM Microscope. Shows event types, PIDs, and timestamps.",
        module: __MODULE__,
        function: :tidewave_get_full_timeline, # Wrapper function
        args: %{} # No arguments for this one
      })

      # Tool 2: Get state history for a specific PID (simplified for Tidewave)
      Tidewave.Plugin.register_tool(%{
        name: "beam_microscope_get_state_history_for_pid",
        description: "Retrieves recorded GenServer state changes for a given PID string (e.g., '<0.123.0>').",
        module: __MODULE__,
        function: :tidewave_get_state_history_for_pid_string, # Wrapper function
        args: %{
          pid_string: %{
            type: "string",
            description: "The PID of the GenServer as a string (e.g., '<0.123.0>')."
          }
        }
      })

      {:ok, :tools_registered}
    else
      IO.puts("[BeamMicroscope.TidewaveIntegration] Tidewave not found. Tools not registered.")
      {:error, :tidewave_not_available}
    end
  end

  # Wrapper function for Tidewave - Full Timeline
  def tidewave_get_full_timeline() do
    # QueryEngine.display_full_timeline/0 prints to IO.
    # For Tidewave, we need to return the data.
    # Let's capture the string output or, preferably, return structured data.
    # For this PoC, we'll return a summary string. A better version would return JSON/Map.

    events = BeamMicroscope.TraceDB.get_all_events() # Explicitly calling TraceDB as per current prompt
    if Enum.empty?(events) do
      "No events recorded by BEAM Microscope."
    else
      summary = Enum.map(events, fn {_id, event} ->
        data_summary = 간단하게_요약(event.data) # Helper to summarize data
        "Timestamp: \#{event.timestamp}, Type: \#{event.type}, Data: \#{data_summary}"
      end)
      Enum.join(summary, "\n---\n")
    end
  end

  # Wrapper function for Tidewave - State History for PID (string input)
  def tidewave_get_state_history_for_pid_string(%{"pid_string" => pid_string}) do
    # Convert pid_string to actual PID
    # Note: :erlang.list_to_pid/1 is risky if format is wrong.
    # A robust implementation would parse carefully.
    pid =
      try do
        String.to_charlist(pid_string) |> :erlang.list_to_pid()
      rescue
        ArgumentError -> nil # Only rescuing ArgumentError as per current prompt
      end

    if pid do
      # Similar to get_full_timeline, we need to return data, not print.
      all_events = BeamMicroscope.TraceDB.get_all_events() # Explicitly calling TraceDB
      state_events =
        Enum.filter(all_events, fn {_id, event} ->
          event.data[:pid] == pid &&
            (event.type == :genserver_state_pre_call || event.type == :genserver_state_post_call)
        end)

      if Enum.empty?(state_events) do
        "No state events recorded for PID: \#{pid_string}"
      else
        summary = Enum.map(state_events, fn {_id, event} ->
          data_summary = 간단하게_요약(event.data)
          "Timestamp: \#{event.timestamp}, Type: \#{event.type}, Data: \#{data_summary}"
        end)
        Enum.join(summary, "\n---\n")
      end
    else
      "Invalid PID string format: \#{pid_string}. Expected format like '<0.123.0>'."
    end
  end
  def tidewave_get_state_history_for_pid_string(_), do: "Error: Missing 'pid_string' argument."


  # Private helper to summarize event data to avoid overly verbose Tidewave responses.
  # A more sophisticated version would handle different event types better.
  defp 간단하게_요약(data_map) when is_map(data_map) do
    data_map
    |> Enum.map(fn {key, value} ->
      cond do
        key in [:state_before, :state_after] && is_map(value) ->
          "\#{key}: [Map with \#{map_size(value)} keys]" # Summarize large states
        key == :message && is_map(value) ->
          "\#{key}: [Message content map]" # As per current prompt
        key == :message -> # Catches binaries after the map case
          "\#{key}: \#{inspect(value, limit: 30)}" # Truncate long messages
        is_pid(value) ->
          "\#{key}: \#{inspect(value)}"
        true ->
          "\#{key}: \#{inspect(value, limit: 50)}" # General truncation
      end
    end)
    |> Enum.join(", ")
  end
  defp 간단하게_요약(other_data), do: inspect(other_data, limit: 50)

end
```
