defmodule ElixirScope.CodeTracer do
  @moduledoc """
  Traces function calls and returns for specific modules.
  
  This module is responsible for:
  - Tracing function calls and returns for specified modules
  - Capturing function arguments and results
  - Providing source code correlation for tracing
  """
  use GenServer
  
  alias ElixirScope.TraceDB
  
  @doc """
  Starts the CodeTracer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Initializes the CodeTracer.
  """
  def init(_opts) do
    # Start with tracing disabled
    {:ok, %{modules: %{}, enabled: false}}
  end
  
  @doc """
  Starts tracing a specific module.
  
  ## Example
  
      ElixirScope.CodeTracer.trace_module(MyApp.User)
  """
  def trace_module(module) do
    GenServer.call(__MODULE__, {:trace_module, module})
  end
  
  @doc """
  Stops tracing a specific module.
  """
  def stop_trace_module(module) do
    GenServer.call(__MODULE__, {:stop_trace_module, module})
  end
  
  @doc """
  Gets information about a traced module.
  """
  def get_module_info(module) do
    GenServer.call(__MODULE__, {:get_module_info, module})
  end
  
  @doc """
  Lists all modules being traced.
  """
  def list_traced_modules do
    GenServer.call(__MODULE__, :list_traced_modules)
  end
  
  # GenServer callbacks
  
  def handle_call({:trace_module, module}, _from, state) do
    if not is_atom(module) do
      {:reply, {:error, :invalid_module}, state}
    else
      try do
        # Start tracer if it's not already started
        new_state = if not state.enabled do
          :dbg.tracer(:process, {fn msg, _ -> handle_trace_msg(msg) end, []})
          %{state | enabled: true}
        else
          state
        end
        
        # Set up function tracing for the module
        :dbg.tpl(module, :_, [{~c"_", [], [{:return_trace}]}])
        
        # Store module source info for reference
        source_info = get_module_source_info(module)
        modules = Map.put(new_state.modules, module, source_info)
        
        {:reply, :ok, %{new_state | modules: modules}}
      rescue
        e -> 
          {:reply, {:error, e}, state}
      end
    end
  end
  
  def handle_call({:stop_trace_module, module}, _from, state) do
    if not is_atom(module) do
      {:reply, {:error, :invalid_module}, state}
    else
      try do
        # Remove tracing for the module
        :dbg.ctpl(module, :_)
        
        # Remove module from state
        modules = Map.delete(state.modules, module)
        
        # If no more modules to trace, stop tracer
        state = if Enum.empty?(modules) do
          :dbg.stop()
          %{state | modules: modules, enabled: false}
        else
          %{state | modules: modules}
        end
        
        {:reply, :ok, state}
      rescue
        e -> 
          {:reply, {:error, e}, state}
      end
    end
  end
  
  def handle_call({:get_module_info, module}, _from, state) do
    module_info = Map.get(state.modules, module)
    {:reply, module_info, state}
  end
  
  def handle_call(:list_traced_modules, _from, state) do
    modules = Map.keys(state.modules)
    {:reply, modules, state}
  end
  
  # Private functions
  
  # Handle trace messages from dbg
  defp handle_trace_msg({:trace, pid, :call, {module, function, args}}) do
    # Record function call events
    TraceDB.store_event(:function, %{
      pid: pid,
      module: module,
      function: function,
      args: sanitize_term(args),
      timestamp: System.monotonic_time(),
      type: :function_call
    })
  end
  
  defp handle_trace_msg({:trace, pid, :return_from, {module, function, arity}, result}) do
    # Record function return events
    TraceDB.store_event(:function, %{
      pid: pid,
      module: module,
      function: function,
      arity: arity,
      result: sanitize_term(result),
      timestamp: System.monotonic_time(),
      type: :function_return
    })
  end
  
  defp handle_trace_msg(_) do
    # Ignore other trace messages
    :ok
  end
  
  # Get source code information for a module
  defp get_module_source_info(module) do
    try do
      # Get module attributes
      attributes = module.__info__(:attributes)
      
      # Try to get file and line information
      module_file = case Code.fetch_docs(module) do
        {:docs_v1, _, _, _, _, _, docs} -> 
          # Get source file from docs metadata
          case List.keyfind(docs, :source, 0) do
            {:source, source_file} -> source_file
            _ -> nil
          end
        _ -> nil
      end
      
      # Try to get function definitions
      functions = module.__info__(:functions)
      
      # Try to get source code if file is available
      source_code = if module_file && File.exists?(module_file) do
        File.read!(module_file)
      else
        nil
      end
      
      # Build module info
      %{
        module: module,
        file: module_file,
        attributes: attributes,
        functions: functions,
        source_code: source_code
      }
    rescue
      _ -> %{module: module, error: :unable_to_read_info}
    end
  end
  
  # Sanitize term for storage (limit size)
  defp sanitize_term(term) do
    try do
      inspect(term, limit: 50, pretty: false)
    rescue
      _ -> "<<error inspecting term>>"
    end
  end
end 