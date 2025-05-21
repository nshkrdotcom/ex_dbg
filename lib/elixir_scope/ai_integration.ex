defmodule ElixirScope.AIIntegration do
  @moduledoc """
  Provides integration with AI systems for natural language debugging.
  
  This module enables:
  - Exposing ElixirScope's debugging capabilities as Tidewave tools
  - AI-assisted analysis of system behavior
  - Exporting trace data in AI-consumable formats
  """
  
  alias ElixirScope.QueryEngine
  
  @doc """
  Sets up AI integration.
  
  Registers ElixirScope tools with Tidewave if it's available.
  """
  def setup do
    if Code.ensure_loaded?(Tidewave) do
      # Register tools with Tidewave's Plugin system
      register_tidewave_tools()
      :ok
    else
      {:error, :tidewave_not_available}
    end
  end

  @doc """
  Registers all ElixirScope tools with Tidewave.
  """
  def register_tidewave_tools do
    # Check if Tidewave.Plugin module is actually available
    if Code.ensure_loaded?(Tidewave.Plugin) && function_exported?(Tidewave.Plugin, :register_tool, 1) do
      # Register the tools only if the module and function exist
      register_all_tools()
    else
      # Return an error if Tidewave.Plugin is not available
      {:error, :tidewave_plugin_not_available}
    end
  end
  
  # Add compiler directive to suppress warnings about undefined function
  @compile {:no_warn_undefined, Tidewave.Plugin}
  
  # Private function to register all tools if Tidewave is available
  defp register_all_tools do
    # Tool 1: Get state timeline for a process
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_get_state_timeline",
      description: "Retrieves the history of state changes for a given process",
      module: __MODULE__,
      function: :tidewave_get_state_timeline,
      args: %{
        pid_string: %{
          type: "string",
          description: "The PID of the process as a string (e.g., '#PID<0.123.0>')"
        }
      }
    })

    # Tool 2: Get message flow between processes
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_get_message_flow",
      description: "Retrieves the message flow between two processes",
      module: __MODULE__,
      function: :tidewave_get_message_flow,
      args: %{
        from_pid: %{
          type: "string",
          description: "The PID of the sender process as a string"
        },
        to_pid: %{
          type: "string",
          description: "The PID of the receiver process as a string"
        }
      }
    })

    # Tool 3: Get function calls for a module
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_get_function_calls",
      description: "Retrieves the function calls for a given module",
      module: __MODULE__,
      function: :tidewave_get_function_calls,
      args: %{
        module_name: %{
          type: "string",
          description: "The name of the module (e.g., 'MyApp.User')"
        }
      }
    })

    # Tool 4: Start tracing a module
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_trace_module",
      description: "Starts tracing a specific module",
      module: __MODULE__,
      function: :tidewave_trace_module,
      args: %{
        module_name: %{
          type: "string",
          description: "The name of the module to trace (e.g., 'MyApp.User')"
        }
      }
    })

    # Tool 5: Start tracing a process
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_trace_process",
      description: "Starts tracing a specific process",
      module: __MODULE__,
      function: :tidewave_trace_process,
      args: %{
        pid_string: %{
          type: "string",
          description: "The PID of the process as a string (e.g., '#PID<0.123.0>')"
        }
      }
    })

    # Tool 6: Start tracing a named process
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_trace_named_process",
      description: "Starts tracing a process by its registered name",
      module: __MODULE__,
      function: :tidewave_trace_named_process,
      args: %{
        process_name: %{
          type: "string",
          description: "The registered name of the process"
        }
      }
    })

    # Tool 7: Get supervision tree
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_get_supervision_tree",
      description: "Retrieves the current supervision tree",
      module: __MODULE__,
      function: :tidewave_get_supervision_tree,
      args: %{}
    })

    # Tool 8: Get execution path for a process
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_get_execution_path",
      description: "Retrieves the execution path of a specific process",
      module: __MODULE__,
      function: :tidewave_get_execution_path,
      args: %{
        pid_string: %{
          type: "string",
          description: "The PID of the process as a string (e.g., '#PID<0.123.0>')"
        }
      }
    })

    # Tool 9: Analyze state changes
    Tidewave.Plugin.register_tool(%{
      name: "elixir_scope_analyze_state_changes",
      description: "Analyzes state changes for a process, including diffs between consecutive states",
      module: __MODULE__, 
      function: :tidewave_analyze_state_changes,
      args: %{
        pid_string: %{
          type: "string",
          description: "The PID of the process as a string (e.g., '#PID<0.123.0>')"
        }
      }
    })
    
    :ok
  end

  # Tidewave tool implementation functions

  @doc false
  def tidewave_get_state_timeline(%{"pid_string" => pid_string}) do
    with pid when not is_nil(pid) <- decode_pid(pid_string),
         history when history != [] <- QueryEngine.state_timeline(pid) do
      
      formatted_states = format_states(history)
      summarized_states = summarize_event_data(formatted_states)
      
      %{
        status: :ok,
        process: pid_to_string(pid),
        state_history: summarized_states
      }
    else
      nil -> %{status: :error, message: "Invalid PID format: #{pid_string}"}
      [] -> %{status: :error, message: "No state history for PID: #{pid_string}"}
    end
  end

  @doc false
  def tidewave_get_message_flow(%{"from_pid" => from_pid_string, "to_pid" => to_pid_string}) do
    with from_pid when not is_nil(from_pid) <- decode_pid(from_pid_string),
         to_pid when not is_nil(to_pid) <- decode_pid(to_pid_string),
         messages when messages != [] <- QueryEngine.message_flow(from_pid, to_pid) do
      
      formatted_messages = format_messages(messages)
      summarized_messages = summarize_event_data(formatted_messages)
      
      %{
        status: :ok,
        from: pid_to_string(from_pid),
        to: pid_to_string(to_pid),
        messages: summarized_messages
      }
    else
      nil -> %{status: :error, message: "Invalid PID format"}
      [] -> %{status: :error, message: "No messages found between these processes"}
    end
  end

  @doc false
  def tidewave_get_function_calls(%{"module_name" => module_name}) do
    try do
      module = String.to_existing_atom("Elixir.#{module_name}")
      calls = QueryEngine.module_function_calls(module)
      
      if Enum.empty?(calls) do
        %{status: :error, message: "No function calls found for module: #{module_name}"}
      else
        formatted_calls = format_function_calls(calls)
        summarized_calls = summarize_event_data(formatted_calls)
        
        %{
          status: :ok,
          module: module_name,
          calls: summarized_calls
        }
      end
    rescue
      ArgumentError -> %{status: :error, message: "Module not found: #{module_name}"}
      e -> %{status: :error, message: "Error: #{inspect(e)}"}
    end
  end

  @doc false
  def tidewave_trace_module(%{"module_name" => module_name}) do
    try do
      module = String.to_existing_atom("Elixir.#{module_name}")
      ElixirScope.trace_module(module)
      
      %{
        status: :ok,
        message: "Now tracing module #{module_name}"
      }
    rescue
      ArgumentError -> %{status: :error, message: "Module not found: #{module_name}"}
      e -> %{status: :error, message: "Error: #{inspect(e)}"}
    end
  end

  @doc false
  def tidewave_trace_process(%{"pid_string" => pid_string}) do
    with pid when not is_nil(pid) <- decode_pid(pid_string) do
      ElixirScope.trace_genserver(pid)
      
      %{
        status: :ok,
        message: "Now tracing process #{pid_to_string(pid)}"
      }
    else
      nil -> %{status: :error, message: "Invalid PID format: #{pid_string}"}
    end
  end

  @doc false
  def tidewave_trace_named_process(%{"process_name" => name}) do
    try do
      pid = process_name_to_pid(name)
      
      if pid do
        ElixirScope.trace_genserver(pid)
        
        %{
          status: :ok,
          message: "Now tracing process #{name} (#{pid_to_string(pid)})"
        }
      else
        %{status: :error, message: "Could not find process named #{name}"}
      end
    rescue
      e -> %{status: :error, message: "Error tracing process: #{inspect(e)}"}
    end
  end

  @doc false
  def tidewave_get_supervision_tree(_args \\ %{}) do
    tree = ElixirScope.ProcessObserver.get_supervision_tree()
    
    %{
      status: :ok,
      supervision_tree: tree
    }
  end

  @doc false
  def tidewave_get_execution_path(%{"pid_string" => pid_string}) do
    with pid when not is_nil(pid) <- decode_pid(pid_string) do
      path = ElixirScope.execution_path(pid)
      
      %{
        status: :ok,
        process: pid_to_string(pid),
        execution_path: path
      }
    else
      nil -> %{status: :error, message: "Invalid PID format: #{pid_string}"}
    end
  end

  @doc false
  def tidewave_analyze_state_changes(%{"pid_string" => pid_string}) do
    with pid when not is_nil(pid) <- decode_pid(pid_string),
         history when history != [] <- QueryEngine.state_timeline(pid) do
      
      # Calculate differences between consecutive states
      state_diffs = history
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [state1, state2] -> 
          %{
            from_id: state1.id,
            to_id: state2.id,
            from_timestamp: state1.timestamp,
            to_timestamp: state2.timestamp,
            diff: QueryEngine.compare_states(state1.state, state2.state)
          }
        end)
      
      summarized_diffs = summarize_event_data(state_diffs)
      
      %{
        status: :ok,
        process: pid_to_string(pid),
        state_diffs: summarized_diffs
      }
    else
      nil -> %{status: :error, message: "Invalid PID format: #{pid_string}"}
      [] -> %{status: :error, message: "No state history for PID: #{pid_string}"}
    end
  end

  # Helper functions

  defp process_name_to_pid(name) do
    try do
      # Try as a registered name atom
      name_atom = String.to_existing_atom(name)
      pid = Process.whereis(name_atom)
      
      # If not found, try as a module name (for named GenServers)
      if is_nil(pid) do
        module = String.to_existing_atom("Elixir.#{name}")
        Process.whereis(module)
      else
        pid
      end
    rescue
      _ -> nil
    end
  end
  
  defp decode_pid(pid_string) do
    try do
      # Handle various PID string formats
      cond do
        String.starts_with?(pid_string, "#PID<") ->
          pid_string
          |> String.replace("#PID<", "")
          |> String.replace(">", "")
          |> :erlang.list_to_pid
          
        String.starts_with?(pid_string, "<") ->
          pid_string
          |> String.replace("<", "")
          |> String.replace(">", "")
          |> :erlang.list_to_pid
          
        true ->
          :erlang.list_to_pid(String.to_charlist(pid_string))
      end
    rescue
      _ -> nil
    end
  end
  
  defp pid_to_string(pid) do
    inspect(pid)
  end
  
  defp format_messages(messages) do
    Enum.map(messages, fn message ->
      %{
        id: message.id,
        from: pid_to_string(message.from_pid),
        to: pid_to_string(message.to_pid),
        message: message.message,
        timestamp: message.timestamp
      }
    end)
  end
  
  defp format_states(states) do
    Enum.map(states, fn state ->
      %{
        id: state.id,
        process: pid_to_string(state.pid),
        state: state.state,
        timestamp: state.timestamp
      }
    end)
  end
  
  defp format_function_calls(calls) do
    Enum.map(calls, fn call ->
      %{
        id: call.id,
        process: pid_to_string(call.pid),
        module: call.module,
        function: call.function,
        args: call.args,
        timestamp: call.timestamp
      }
    end)
  end

  # Helper to summarize event data to avoid overly verbose responses
  defp summarize_event_data(data) when is_list(data) do
    Enum.map(data, &summarize_single_item/1)
  end

  defp summarize_single_item(item) when is_map(item) do
    item
    |> Enum.map(fn {key, value} ->
      cond do
        key in [:state, :args, :message] && is_map(value) ->
          {key, "#{inspect(value, limit: 50)}"}
        key == :diff && is_map(value) ->
          {key, Enum.map(value, fn {k, v} -> "#{k}: #{inspect(v, limit: 30)}" end)}
        is_map(value) || is_list(value) ->
          {key, inspect(value, limit: 50)}
        true ->
          {key, value}
      end
    end)
    |> Map.new()
  end
  defp summarize_single_item(item), do: item
end 