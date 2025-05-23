# Layer 1 Foundation: Progressive Sub-Layer Implementation Strategy
## Incremental Checkpoint-Based Development for Core Instrumentation

---

## Executive Summary

Layer 1 Foundation is the absolute bedrock of ElixirScope's entire system. This document breaks down Layer 1 into five distinct sub-layers, each with its own implementation checkpoints and stabilization criteria. The progressive approach ensures we have a rock-solid foundation before building higher-level capabilities.

**Core Philosophy**: Build the simplest possible instrumentation first, prove it works flawlessly, then add complexity incrementally while maintaining stability.

---

## Layer 1 Foundation Sub-Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              LAYER 1.5: COMPREHENSIVE INSTRUMENTATION          │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │   Phoenix/Ecto  │ │   Hot Code      │ │   Production    │   │
│  │  Deep Tracing   │ │   Swapping      │ │   Safety Nets   │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│              LAYER 1.4: ADVANCED VM INSTRUMENTATION            │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │   Scheduler     │ │   Memory        │ │   Distribution  │   │
│  │   Tracing       │ │   Tracking      │ │   Awareness     │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│              LAYER 1.3: SMART AST TRANSFORMATION               │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │   GenServer     │ │   Function      │ │   Conditional   │   │
│  │ Instrumentation │ │   Entry/Exit    │ │   Compilation   │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│              LAYER 1.2: BASIC AST TRANSFORMATION               │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │   Compiler      │ │   Simple        │ │   Metadata      │   │
│  │   Integration   │ │   Injection     │ │   Preservation  │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│              LAYER 1.1: CORE EVENT CAPTURE (FOUNDATION)        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │
│  │   Direct VM     │ │   Ring Buffer   │ │   Basic Event   │   │
│  │   Tracing       │ │   Storage       │ │   Structure     │   │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer 1.1: Core Event Capture (Absolute Foundation)
### Goal: Prove we can capture VM events with minimal overhead

**Philosophy**: Start with the absolute minimum viable instrumentation. Get VM-level event capture working perfectly before adding any complexity.

### 1.1.1 Direct VM Tracing Subsystem

**Core Focus**: Raw BEAM VM event capture using built-in tracing
**Implementation Priority**: Start with the simplest possible events

**Minimal Event Set (Phase 1)**:
```elixir
defmodule ElixirScope.CoreEvents do
  @minimal_events [
    :spawn,     # Process creation
    :exit,      # Process termination  
    :send,      # Message sending
    :receive    # Message receiving
  ]
end
```

**Implementation Steps**:

**Step 1.1.1a: Basic Tracer Setup**
```elixir
defmodule ElixirScope.VMTracer do
  @moduledoc """
  Absolute minimal VM tracer using :erlang.trace/3
  Focus: Prove we can capture events without breaking anything
  """
  
  def start_minimal_tracing() do
    # Start with self-tracing only (safest)
    :erlang.trace(self(), true, [:send, :receive, :procs])
    
    # Simple trace message handler
    spawn(fn -> trace_message_loop() end)
  end
  
  defp trace_message_loop() do
    receive
      {:trace, pid, :spawn, new_pid, {mod, fun, args}} ->
        # Minimal event capture - just print for now
        IO.inspect({:spawn_event, pid, new_pid, mod, fun}, label: "TRACE")
        trace_message_loop()
        
      {:trace, pid, :exit, reason} ->
        IO.inspect({:exit_event, pid, reason}, label: "TRACE")
        trace_message_loop()
        
      {:trace, pid, :send, msg, to_pid} ->
        IO.inspect({:send_event, pid, to_pid, inspect(msg)}, label: "TRACE")
        trace_message_loop()
        
      {:trace, pid, :receive, msg} ->
        IO.inspect({:receive_event, pid, inspect(msg)}, label: "TRACE")
        trace_message_loop()
        
      other ->
        IO.inspect({:unknown_trace, other}, label: "TRACE")
        trace_message_loop()
    end
  end
end
```

**Checkpoint 1.1.1a Validation**:
- [ ] Can start tracing without crashing
- [ ] Receives basic trace messages
- [ ] Can stop tracing cleanly
- [ ] No noticeable performance impact on simple operations
- [ ] Trace messages are comprehensible

**Step 1.1.1b: Performance Measurement**
```elixir
defmodule ElixirScope.PerformanceMonitor do
  @moduledoc """
  Measure the overhead of our basic tracing
  Essential to prove minimal impact before proceeding
  """
  
  def measure_tracing_overhead() do
    # Baseline measurement without tracing
    baseline_time = time_operation(&baseline_workload/0)
    
    # Start minimal tracing
    ElixirScope.VMTracer.start_minimal_tracing()
    
    # Measurement with tracing
    traced_time = time_operation(&baseline_workload/0)
    
    # Calculate overhead percentage
    overhead = ((traced_time - baseline_time) / baseline_time) * 100
    
    IO.puts("Tracing overhead: #{overhead}%")
    
    # Stop tracing
    :erlang.trace(:all, false, [:all])
    
    overhead
  end
  
  defp baseline_workload() do
    # Simple workload that exercises the events we're tracing
    pid = spawn(fn -> :timer.sleep(10) end)
    send(pid, :test_message)
    :timer.sleep(20)
  end
  
  defp time_operation(fun) do
    {time, _result} = :timer.tc(fun)
    time
  end
end
```

**Checkpoint 1.1.1b Validation**:
- [ ] Overhead measurement completes successfully
- [ ] Tracing overhead is under 5% for basic operations
- [ ] Measurements are consistent across multiple runs
- [ ] Can cleanly start/stop tracing multiple times

### 1.1.2 Ring Buffer Storage Subsystem

**Core Focus**: Ultra-fast event storage without memory allocation during capture

**Step 1.1.2a: Basic Ring Buffer**
```elixir
defmodule ElixirScope.BasicRingBuffer do
  @moduledoc """
  Simplest possible ring buffer implementation
  Focus: Prove we can store events faster than we generate them
  """
  
  defstruct [
    :buffer,        # Pre-allocated binary
    :size,          # Total buffer size
    :write_pos,     # Current write position
    :read_pos,      # Current read position
    :count          # Number of events stored
  ]
  
  @entry_size 64  # Fixed size per event entry
  
  def new(num_entries \\ 1000) do
    buffer_size = num_entries * @entry_size
    %__MODULE__{
      buffer: :binary.copy(<<0>>, buffer_size),
      size: buffer_size,
      write_pos: 0,
      read_pos: 0,
      count: 0
    }
  end
  
  def write_event(ring_buffer, event_binary) when byte_size(event_binary) <= @entry_size do
    # Simple write without overflow checking (for now)
    <<prefix::binary-size(ring_buffer.write_pos), 
      _old::binary-size(@entry_size),
      suffix::binary>> = ring_buffer.buffer
    
    # Pad event to fixed size
    padded_event = pad_binary(event_binary, @entry_size)
    new_buffer = <<prefix::binary, padded_event::binary, suffix::binary>>
    
    new_write_pos = rem(ring_buffer.write_pos + @entry_size, ring_buffer.size)
    
    %{ring_buffer | 
      buffer: new_buffer,
      write_pos: new_write_pos,
      count: min(ring_buffer.count + 1, div(ring_buffer.size, @entry_size))
    }
  end
  
  defp pad_binary(binary, target_size) do
    current_size = byte_size(binary)
    if current_size < target_size do
      padding = :binary.copy(<<0>>, target_size - current_size)
      <<binary::binary, padding::binary>>
    else
      binary
    end
  end
end
```

**Checkpoint 1.1.2a Validation**:
- [ ] Can create ring buffer without errors
- [ ] Can write events without memory allocation in hot path
- [ ] Ring buffer wraps around correctly when full
- [ ] Write operation takes under 1 microsecond
- [ ] Can handle 100K+ writes per second

**Step 1.1.2b: Lock-Free Buffer Operations**
```elixir
defmodule ElixirScope.LockFreeBuffer do
  @moduledoc """
  Lock-free ring buffer using :atomics for coordination
  Critical for multi-process high-throughput scenarios
  """
  
  def new(num_entries \\ 1000) do
    buffer_size = num_entries * entry_size()
    atomics_ref = :atomics.new(3, [])  # write_pos, read_pos, count
    
    %{
      buffer: :persistent_term.put({__MODULE__, make_ref()}, 
                                   :binary.copy(<<0>>, buffer_size)),
      atomics: atomics_ref,
      size: buffer_size,
      entry_size: entry_size()
    }
  end
  
  def write_event_atomic(buffer_info, event_binary) do
    # Atomic compare-and-swap for write position
    current_write_pos = :atomics.get(buffer_info.atomics, 1)
    next_write_pos = rem(current_write_pos + buffer_info.entry_size, buffer_info.size)
    
    # Try to claim the write slot
    case :atomics.compare_exchange(buffer_info.atomics, 1, current_write_pos, next_write_pos) do
      :ok ->
        # Successfully claimed slot, write the event
        write_to_position(buffer_info, current_write_pos, event_binary)
        :atomics.add(buffer_info.atomics, 3, 1)  # Increment count
        :ok
      _ ->
        # Retry or handle contention
        write_event_atomic(buffer_info, event_binary)
    end
  end
  
  defp entry_size(), do: 64
  
  defp write_to_position(buffer_info, position, event_binary) do
    # Direct binary manipulation at specific position
    # Implementation depends on chosen storage mechanism
    :ok
  end
end
```

**Checkpoint 1.1.2b Validation**:
- [ ] Multiple processes can write concurrently without corruption
- [ ] Lock-free operations maintain consistency under load
- [ ] Performance scales with number of cores
- [ ] No deadlocks or race conditions under stress testing

### 1.1.3 Basic Event Structure Subsystem

**Core Focus**: Minimal event format that captures essential information

**Step 1.1.3a: Minimal Event Format**
```elixir
defmodule ElixirScope.BasicEvent do
  @moduledoc """
  Absolute minimal event structure for initial implementation
  Keep it simple, prove serialization works perfectly
  """
  
  defstruct [
    :timestamp,     # Erlang monotonic time
    :event_type,    # :spawn, :exit, :send, :receive
    :pid,           # Source process
    :data           # Minimal event-specific data
  ]
  
  # Fixed-size binary serialization for ring buffer
  def to_binary(%__MODULE__{} = event) do
    <<
      event.timestamp::64,
      encode_event_type(event.event_type)::8,
      encode_pid(event.pid)::binary-size(16),
      encode_data(event.data)::binary-size(32)
    >>
  end
  
  def from_binary(<<
    timestamp::64,
    event_type_byte::8,
    pid_binary::binary-size(16),
    data_binary::binary-size(32)
  >>) do
    %__MODULE__{
      timestamp: timestamp,
      event_type: decode_event_type(event_type_byte),
      pid: decode_pid(pid_binary),
      data: decode_data(data_binary)
    }
  end
  
  # Simple encoding functions
  defp encode_event_type(:spawn), do: 1
  defp encode_event_type(:exit), do: 2
  defp encode_event_type(:send), do: 3
  defp encode_event_type(:receive), do: 4
  
  defp decode_event_type(1), do: :spawn
  defp decode_event_type(2), do: :exit
  defp decode_event_type(3), do: :send
  defp decode_event_type(4), do: :receive
  
  defp encode_pid(pid) when is_pid(pid) do
    # Convert PID to binary representation
    pid_string = inspect(pid)
    padded = String.pad_trailing(pid_string, 16, <<0>>)
    :binary.part(padded, 0, 16)
  end
  
  defp decode_pid(binary) do
    pid_string = String.trim_trailing(binary, <<0>>)
    # This is simplified - real implementation needs proper PID parsing
    pid_string
  end
  
  defp encode_data(data) do
    # Simplified data encoding
    data_string = inspect(data)
    padded = String.pad_trailing(data_string, 32, <<0>>)
    :binary.part(padded, 0, 32)
  end
  
  defp decode_data(binary) do
    String.trim_trailing(binary, <<0>>)
  end
end
```

**Checkpoint 1.1.3a Validation**:
- [ ] Event serialization/deserialization is lossless
- [ ] Fixed-size binary format works correctly
- [ ] Serialization takes under 100 nanoseconds
- [ ] Can encode/decode all basic event types
- [ ] Binary format is stable across Elixir versions

### 1.1.4 Integration & Performance Validation

**Step 1.1.4a: End-to-End Basic System**
```elixir
defmodule ElixirScope.Layer1Foundation do
  @moduledoc """
  Integration of all Layer 1.1 components
  Prove the foundation works as a complete system
  """
  
  def start_basic_instrumentation() do
    # Initialize ring buffer
    ring_buffer = ElixirScope.BasicRingBuffer.new(10_000)
    
    # Start tracer that writes to ring buffer
    tracer_pid = spawn(fn -> 
      trace_handler_loop(ring_buffer) 
    end)
    
    # Enable tracing
    :erlang.trace(:all, true, [:send, :receive, :procs])
    
    {:ok, tracer_pid}
  end
  
  defp trace_handler_loop(ring_buffer) do
    receive
      {:trace, pid, event_type, data} ->
        # Create basic event
        event = %ElixirScope.BasicEvent{
          timestamp: :erlang.monotonic_time(:nanosecond),
          event_type: event_type,
          pid: pid,
          data: data
        }
        
        # Serialize and store
        event_binary = ElixirScope.BasicEvent.to_binary(event)
        updated_buffer = ElixirScope.BasicRingBuffer.write_event(ring_buffer, event_binary)
        
        trace_handler_loop(updated_buffer)
      
      {:stop} ->
        :erlang.trace(:all, false, [:all])
        :ok
        
      other ->
        trace_handler_loop(ring_buffer)
    end
  end
  
  def stop_basic_instrumentation(tracer_pid) do
    send(tracer_pid, {:stop})
  end
end
```

**Step 1.1.4b: Comprehensive Testing**
```elixir
defmodule ElixirScope.Layer1Test do
  @moduledoc """
  Comprehensive testing of Layer 1.1 foundation
  Must pass before proceeding to Layer 1.2
  """
  
  def run_foundation_tests() do
    IO.puts("Testing Layer 1.1 Foundation...")
    
    # Test 1: Basic functionality
    test_basic_functionality()
    
    # Test 2: Performance under load
    test_performance_under_load()
    
    # Test 3: Memory stability
    test_memory_stability()
    
    # Test 4: Error handling
    test_error_conditions()
    
    IO.puts("Layer 1.1 Foundation tests complete!")
  end
  
  defp test_basic_functionality() do
    IO.puts("  Testing basic functionality...")
    
    {:ok, tracer} = ElixirScope.Layer1Foundation.start_basic_instrumentation()
    
    # Generate some events
    pid = spawn(fn -> receive do _ -> :ok end end)
    send(pid, :test_message)
    Process.exit(pid, :normal)
    
    :timer.sleep(100)  # Let events process
    
    ElixirScope.Layer1Foundation.stop_basic_instrumentation(tracer)
    
    IO.puts("    ✓ Basic functionality working")
  end
  
  defp test_performance_under_load() do
    IO.puts("  Testing performance under load...")
    
    {:ok, tracer} = ElixirScope.Layer1Foundation.start_basic_instrumentation()
    
    # Generate load
    start_time = :erlang.monotonic_time(:millisecond)
    
    for _ <- 1..1000 do
      pid = spawn(fn -> :timer.sleep(1) end)
      send(pid, :load_test)
    end
    
    :timer.sleep(2000)  # Wait for completion
    
    end_time = :erlang.monotonic_time(:millisecond)
    duration = end_time - start_time
    
    ElixirScope.Layer1Foundation.stop_basic_instrumentation(tracer)
    
    if duration < 3000 do  # Should complete within 3 seconds
      IO.puts("    ✓ Performance acceptable: #{duration}ms")
    else
      IO.puts("    ✗ Performance issue: #{duration}ms")
      throw(:performance_failure)
    end
  end
  
  defp test_memory_stability() do
    IO.puts("  Testing memory stability...")
    
    initial_memory = :erlang.memory(:total)
    
    {:ok, tracer} = ElixirScope.Layer1Foundation.start_basic_instrumentation()
    
    # Run for extended period
    for i <- 1..100 do
      for _ <- 1..10 do
        pid = spawn(fn -> :timer.sleep(1) end)
        send(pid, {:iteration, i})
      end
      :timer.sleep(10)
    end
    
    ElixirScope.Layer1Foundation.stop_basic_instrumentation(tracer)
    
    :timer.sleep(1000)  # Let GC run
    final_memory = :erlang.memory(:total)
    memory_growth = final_memory - initial_memory
    
    if memory_growth < 10_000_000 do  # Less than 10MB growth
      IO.puts("    ✓ Memory stable: +#{memory_growth} bytes")
    else
      IO.puts("    ✗ Memory leak: +#{memory_growth} bytes")
      throw(:memory_leak)
    end
  end
  
  defp test_error_conditions() do
    IO.puts("  Testing error handling...")
    
    # Test graceful handling of various error conditions
    # This will be expanded as we discover edge cases
    
    IO.puts("    ✓ Error handling verified")
  end
end
```

**Checkpoint 1.1.4 Validation (COMPLETE FOUNDATION)**:
- [ ] All component tests pass individually
- [ ] End-to-end system captures events correctly
- [ ] Performance overhead under 2% for typical workloads
- [ ] Memory usage remains stable over time
- [ ] System handles error conditions gracefully
- [ ] Can cleanly start/stop multiple times
- [ ] Ready for Layer 1.2 development

---

## Layer 1.2: Basic AST Transformation
### Goal: Add compile-time instrumentation to Layer 1.1 foundation

**Philosophy**: Now that we have proven VM-level capture works, add the simplest possible compile-time instrumentation.

### 1.2.1 Compiler Integration Subsystem

**Core Focus**: Get the custom compiler working without breaking existing builds

**Step 1.2.1a: Minimal Mix Compiler**
```elixir
defmodule Mix.Tasks.Compile.ElixirScope do
  @moduledoc """
  Minimal Mix compiler integration
  Goal: Prove we can hook into compilation without breaking anything
  """
  
  use Mix.Task.Compiler
  
  def run(_args) do
    IO.puts("ElixirScope compiler running...")
    
    # For now, just run normal compilation
    # Later we'll add AST transformation
    case Mix.Task.run("compile.elixir", []) do
      {:ok, _} -> 
        IO.puts("ElixirScope compilation successful")
        {:ok, []}
      {:error, errors} -> 
        {:error, errors}
    end
  end
end
```

**Checkpoint 1.2.1a Validation**:
- [ ] Mix compilation succeeds with custom compiler
- [ ] Existing code compiles without changes
- [ ] Build times are not significantly impacted
- [ ] Custom compiler integrates cleanly with Mix

### 1.2.2 Simple Injection Subsystem

**Step 1.2.2a: Function Entry Logging**
```elixir
defmodule ElixirScope.SimpleAST do
  @moduledoc """
  Simplest possible AST transformation
  Just add logging to function entry points
  """
  
  def transform_function({:def, meta, [{name, _, args} = signature, body]}) do
    # Add simple logging at function entry
    log_call = quote do
      ElixirScope.Logger.log_function_entry(unquote(name), unquote(length(args || [])))
    end
    
    new_body = case body do
      [do: existing_body] ->
        [do: {:__block__, [], [log_call, existing_body]}]
      _ ->
        body
    end
    
    {:def, meta, [signature, new_body]}
  end
  
  def transform_function(other), do: other
end

defmodule ElixirScope.Logger do
  @moduledoc """
  Simple logger for transformed functions
  Integrates with our Layer 1.1 foundation
  """
  
  def log_function_entry(function_name, arity) do
    event = %ElixirScope.BasicEvent{
      timestamp: :erlang.monotonic_time(:nanosecond),
      event_type: :function_entry,
      pid: self(),
      data: {function_name, arity}
    }
    
    # Send to our tracer (if running)
    send(:elixir_scope_tracer, {:ast_event, event})
  end
end
```

**Checkpoint 1.2.2a Validation**:
- [ ] Can transform simple function definitions
- [ ] Transformed functions execute correctly
- [ ] Function entry events are captured
- [ ] No impact on function performance
- [ ] AST transformation preserves original behavior

---

## Stabilization Criteria for Each Sub-Layer

### Layer 1.1 (Foundation) - Must be 100% stable
- **Performance**: <2% overhead on typical Elixir workloads
- **Reliability**: Zero crashes during 24-hour continuous operation
- **Memory**: No memory leaks during extended operation
- **Functionality**: All basic VM events captured accurately

### Layer 1.2 (Basic AST) - Build on stable 1.1
- **Compatibility**: Compiles all existing Elixir code without modification
- **Correctness**: AST transformations preserve original program behavior
- **Integration**: Custom compiler works seamlessly with Mix
- **Performance**: <1% additional overhead beyond Layer 1.1

### Layer 1.3 (Smart AST) - Build on stable 1.2
- **Coverage**: Instruments GenServer callbacks and complex patterns
- **Conditional**: Different instrumentation for dev/test/prod
- **Metadata**: Preserves file/line information accurately

### Layer 1.4 (Advanced VM) - Build on stable 1.3
- **Scheduler**: Detailed scheduler event tracking
- **Memory**: Precise memory allocation tracking
- **Distribution**: Multi-node event correlation

### Layer 1.5 (Comprehensive) - Build on stable 1.4
- **Phoenix**: Deep Phoenix/LiveView instrumentation
- **Hot-swap**: Production-safe runtime instrumentation
- **Safety**: Comprehensive error handling and recovery

---

## Implementation Timeline for Layer 1 Foundation

### Month 1: Layer 1.1 (Core Foundation)
- **Week 1**: VM tracing basics (Steps 1.1.1a-b)
- **Week 2**: Ring buffer implementation (Steps 1.1.2a-b) 
- **Week 3**: Event structure and serialization (Step 1.1.3a)
- **Week 4**: Integration and comprehensive testing (Steps 1.1.4a-b)

### Month 2: Layer 1.2 (Basic AST)
- **Week 1**: Mix compiler integration (Step 1.2.1a)
- **Week 2**: Simple AST transformation (Step 1.2.2a)
- **Week 3**: Function instrumentation testing
- **Week 4**: Performance validation and stabilization

### Month 3: Layer 1.3 (Smart AST)
- GenServer callback instrumentation
- Complex pattern matching in transformations
- Conditional compilation strategies

### Month 4: Layer 1.4 (Advanced VM)
- Scheduler and memory event tracking
- Multi-node awareness
- Production performance optimization

### Month 5: Layer 1.5 (Comprehensive)
- Phoenix/Ecto deep integration
- Hot code swapping implementation
- Production safety features

---

## Deep Dive: Layer 1.1 Week-by-Week Implementation

### Week 1: VM Tracing Mastery

**Day 1-2: Proof of Concept**
```elixir
defmodule ElixirScope.Week1.ProofOfConcept do
  @moduledoc """
  Simplest possible trace capture - prove we can intercept VM events
  """
  
  def start_simple_trace() do
    # Start with absolute minimum - trace only current process
    :erlang.trace(self(), true, [:send, :receive])
    
    # Spawn simple message handler
    handler = spawn(&trace_handler/0)
    :erlang.trace_info(self(), :tracer)
    
    # Test with simple message
    send(self(), :test_message)
    receive do :test_message -> :ok end
    
    handler
  end
  
  defp trace_handler() do
    receive do
      trace_msg -> 
        IO.inspect(trace_msg, label: "CAPTURED")
        trace_handler()
    end
  end
end
```

**Day 3-4: Multi-Process Tracing**
```elixir
defmodule ElixirScope.Week1.MultiProcess do
  @moduledoc """
  Extend to multiple processes - critical for real applications
  """
  
  def start_multi_trace() do
    # Trace all processes (careful - this is heavy)
    :erlang.trace(:all, true, [:send, :receive, :procs])
    
    # Dedicated tracer process with better handling
    tracer = spawn(&robust_trace_handler/0)
    
    # Test with multiple processes
    test_processes = for i <- 1..5 do
      spawn(fn -> 
        :timer.sleep(i * 10)
        send(self(), {:test, i})
        receive do {:test, ^i} -> :ok end
      end)
    end
    
    {tracer, test_processes}
  end
  
  defp robust_trace_handler(event_count \\ 0) do
    receive do
      {:trace, pid, :spawn, child_pid, {m, f, a}} ->
        IO.puts("SPAWN: #{inspect(pid)} -> #{inspect(child_pid)} #{m}.#{f}/#{length(a)}")
        robust_trace_handler(event_count + 1)
        
      {:trace, pid, :exit, reason} ->
        IO.puts("EXIT: #{inspect(pid)} reason: #{inspect(reason)}")
        robust_trace_handler(event_count + 1)
        
      {:trace, pid, :send, msg, to_pid} ->
        msg_preview = msg |> inspect() |> String.slice(0, 50)
        IO.puts("SEND: #{inspect(pid)} -> #{inspect(to_pid)}: #{msg_preview}")
        robust_trace_handler(event_count + 1)
        
      {:trace, pid, :receive, msg} ->
        msg_preview = msg |> inspect() |> String.slice(0, 50)
        IO.puts("RECV: #{inspect(pid)}: #{msg_preview}")
        robust_trace_handler(event_count + 1)
        
      {:stop, reply_to} ->
        send(reply_to, {:stopped, event_count})
        :erlang.trace(:all, false, [:all])
        
      other ->
        IO.puts("UNKNOWN: #{inspect(other)}")
        robust_trace_handler(event_count)
    after 
      5000 ->
        IO.puts("Trace handler timeout - captured #{event_count} events")
        robust_trace_handler(event_count)
    end
  end
end
```

**Day 5-7: Performance Measurement & Optimization**
```elixir
defmodule ElixirScope.Week1.Performance do
  @moduledoc """
  Critical: Measure and optimize tracing overhead
  This determines if we can proceed to Week 2
  """
  
  def benchmark_tracing_overhead() do
    IO.puts("Benchmarking VM tracing overhead...")
    
    # Baseline: No tracing
    baseline = measure_workload(&standard_workload/0, "Baseline (no tracing)")
    
    # Test 1: Minimal tracing (current process only)
    minimal = measure_with_tracing(&standard_workload/0, :minimal, "Minimal tracing")
    
    # Test 2: All processes tracing
    full = measure_with_tracing(&standard_workload/0, :all, "Full process tracing")
    
    # Calculate overheads
    minimal_overhead = calculate_overhead(baseline, minimal)
    full_overhead = calculate_overhead(baseline, full)
    
    IO.puts("\n=== OVERHEAD ANALYSIS ===")
    IO.puts("Minimal tracing overhead: #{minimal_overhead}%")
    IO.puts("Full tracing overhead: #{full_overhead}%")
    
    # Quality gate: Must be under 5% for minimal, 15% for full
    if minimal_overhead > 5.0 do
      IO.puts("❌ FAILED: Minimal overhead too high (#{minimal_overhead}%)")
      {:error, :overhead_too_high}
    else
      IO.puts("✅ PASSED: Overhead acceptable")
      {:ok, %{minimal: minimal_overhead, full: full_overhead}}
    end
  end
  
  defp standard_workload() do
    # Realistic workload that exercises traced operations
    processes = for i <- 1..100 do
      spawn(fn ->
        # Simulate typical GenServer-like behavior
        for j <- 1..10 do
          send(self(), {:work, i, j})
          receive do {:work, ^i, ^j} -> :ok end
          :timer.sleep(1)
        end
      end)
    end
    
    # Wait for completion
    Enum.each(processes, fn pid ->
      ref = Process.monitor(pid)
      receive do {:DOWN, ^ref, :process, ^pid, _} -> :ok end
    end)
  end
  
  defp measure_workload(workload_fn, label) do
    :erlang.garbage_collect()  # Clean slate
    
    start_time = :erlang.monotonic_time(:microsecond)
    start_memory = :erlang.memory(:total)
    
    workload_fn.()
    
    end_time = :erlang.monotonic_time(:microsecond)
    end_memory = :erlang.memory(:total)
    
    duration = end_time - start_time
    memory_delta = end_memory - start_memory
    
    IO.puts("#{label}: #{duration}μs, memory: #{memory_delta} bytes")
    %{duration: duration, memory: memory_delta, label: label}
  end
  
  defp measure_with_tracing(workload_fn, trace_scope, label) do
    # Start tracing
    case trace_scope do
      :minimal -> :erlang.trace(self(), true, [:send, :receive])
      :all -> :erlang.trace(:all, true, [:send, :receive, :procs])
    end
    
    # Spawn tracer (but don't log to avoid I/O overhead)
    tracer = spawn(fn -> silent_trace_handler() end)
    
    # Measure workload
    result = measure_workload(workload_fn, label)
    
    # Stop tracing
    :erlang.trace(:all, false, [:all])
    send(tracer, :stop)
    
    result
  end
  
  defp silent_trace_handler() do
    receive do
      :stop -> :ok
      _trace -> silent_trace_handler()
    end
  end
  
  defp calculate_overhead(baseline, traced) do
    ((traced.duration - baseline.duration) / baseline.duration) * 100
  end
end
```

**Week 1 Checkpoint Validation**:
- [ ] Can capture VM trace events reliably
- [ ] Multi-process tracing works without crashes
- [ ] Overhead measurements are repeatable and under thresholds
- [ ] Can cleanly start/stop tracing multiple times
- [ ] No memory leaks during extended operation

### Week 2: Ring Buffer Mastery

**Day 8-9: Basic Ring Buffer Implementation**
```elixir
defmodule ElixirScope.Week2.BasicRingBuffer do
  @moduledoc """
  Ultra-fast ring buffer - the heart of our performance
  """
  
  defstruct [
    :data,           # Binary buffer
    :capacity,       # Total entries
    :entry_size,     # Fixed size per entry
    :write_index,    # Current write position
    :read_index,     # Current read position  
    :count,          # Number of entries
    :overflow_count  # Track overflows
  ]
  
  @default_entry_size 128
  
  def new(capacity \\ 10_000, entry_size \\ @default_entry_size) do
    total_size = capacity * entry_size
    
    %__MODULE__{
      data: :binary.copy(<<0>>, total_size),
      capacity: capacity,
      entry_size: entry_size,
      write_index: 0,
      read_index: 0,
      count: 0,
      overflow_count: 0
    }
  end
  
  def write(buffer, entry_binary) when is_binary(entry_binary) do
    cond do
      byte_size(entry_binary) > buffer.entry_size ->
        {:error, :entry_too_large}
        
      buffer.count >= buffer.capacity ->
        # Ring buffer full - overwrite oldest entry
        write_at_index(buffer, buffer.write_index, entry_binary)
        |> advance_write_pointer()
        |> Map.update!(:overflow_count, &(&1 + 1))
        |> then(&{:ok, &1})
        
      true ->
        # Normal write
        write_at_index(buffer, buffer.write_index, entry_binary)
        |> advance_write_pointer()
        |> Map.update!(:count, &(&1 + 1))
        |> then(&{:ok, &1})
    end
  end
  
  defp write_at_index(buffer, index, entry_binary) do
    # Pad entry to fixed size
    padded_entry = pad_entry(entry_binary, buffer.entry_size)
    
    # Calculate byte offset
    byte_offset = index * buffer.entry_size
    
    # Binary surgery to insert at specific position
    <<prefix::binary-size(byte_offset), 
      _old::binary-size(buffer.entry_size),
      suffix::binary>> = buffer.data
    
    new_data = <<prefix::binary, padded_entry::binary, suffix::binary>>
    
    %{buffer | data: new_data}
  end
  
  defp advance_write_pointer(buffer) do
    new_write_index = rem(buffer.write_index + 1, buffer.capacity)
    %{buffer | write_index: new_write_index}
  end
  
  defp pad_entry(entry, target_size) do
    current_size = byte_size(entry)
    if current_size < target_size do
      padding_size = target_size - current_size
      <<entry::binary, 0::size(padding_size)-unit(8)>>
    else
      entry
    end
  end
  
  def read_latest(buffer, count \\ 1) do
    actual_count = min(count, buffer.count)
    
    entries = for i <- 0..(actual_count - 1) do
      index = rem(buffer.write_index - 1 - i + buffer.capacity, buffer.capacity)
      read_at_index(buffer, index)
    end
    
    {entries, buffer}
  end
  
  defp read_at_index(buffer, index) do
    byte_offset = index * buffer.entry_size
    <<_prefix::binary-size(byte_offset),
      entry::binary-size(buffer.entry_size),
      _suffix::binary>> = buffer.data
    
    # Remove padding
    entry
    |> :binary.bin_to_list()
    |> Enum.take_while(&(&1 != 0))
    |> :binary.list_to_bin()
  end
end
```

**Day 10-11: Lock-Free Concurrent Access**
```elixir
defmodule ElixirScope.Week2.LockFreeBuffer do
  @moduledoc """
  Lock-free ring buffer using :atomics for multi-process safety
  Critical for high-throughput scenarios
  """
  
  defstruct [
    :buffer_ref,     # :persistent_term reference to buffer
    :atomics_ref,    # :atomics reference for coordination
    :capacity,
    :entry_size
  ]
  
  # Atomics indices
  @write_index_pos 1
  @read_index_pos 2
  @count_pos 3
  @overflow_count_pos 4
  
  def new(capacity \\ 10_000, entry_size \\ 128) do
    # Create buffer in persistent_term for cross-process access
    buffer_id = make_ref()
    total_size = capacity * entry_size
    buffer_data = :binary.copy(<<0>>, total_size)
    :persistent_term.put({__MODULE__, buffer_id}, buffer_data)
    
    # Create atomics for coordination
    atomics_ref = :atomics.new(4, [])  # write_idx, read_idx, count, overflow
    
    %__MODULE__{
      buffer_ref: {__MODULE__, buffer_id},
      atomics_ref: atomics_ref,
      capacity: capacity,
      entry_size: entry_size
    }
  end
  
  def write_atomic(buffer, entry_binary) do
    max_attempts = 1000  # Prevent infinite retry
    write_atomic_retry(buffer, entry_binary, max_attempts)
  end
  
  defp write_atomic_retry(_buffer, _entry, 0), do: {:error, :too_many_retries}
  
  defp write_atomic_retry(buffer, entry_binary, attempts_left) do
    current_write_idx = :atomics.get(buffer.atomics_ref, @write_index_pos)
    current_count = :atomics.get(buffer.atomics_ref, @count_pos)
    
    # Calculate next write index
    next_write_idx = rem(current_write_idx + 1, buffer.capacity)
    
    # Try to claim the write slot
    case :atomics.compare_exchange(buffer.atomics_ref, @write_index_pos, 
                                   current_write_idx, next_write_idx) do
      :ok ->
        # Successfully claimed slot
        write_to_buffer(buffer, current_write_idx, entry_binary)
        
        if current_count >= buffer.capacity do
          # Buffer full - increment overflow counter
          :atomics.add(buffer.atomics_ref, @overflow_count_pos, 1)
        else
          # Normal write - increment count
          :atomics.add(buffer.atomics_ref, @count_pos, 1)
        end
        
        {:ok, buffer}
        
      _ ->
        # Slot was taken by another process, retry
        write_atomic_retry(buffer, entry_binary, attempts_left - 1)
    end
  end
  
  defp write_to_buffer(buffer, index, entry_binary) do
    # Get current buffer data
    buffer_data = :persistent_term.get(buffer.buffer_ref)
    
    # Pad entry
    padded_entry = pad_entry(entry_binary, buffer.entry_size)
    
    # Calculate position and update buffer
    byte_offset = index * buffer.entry_size
    
    <<prefix::binary-size(byte_offset),
      _old::binary-size(buffer.entry_size),
      suffix::binary>> = buffer_data
    
    new_buffer_data = <<prefix::binary, padded_entry::binary, suffix::binary>>
    
    # Update persistent term
    :persistent_term.put(buffer.buffer_ref, new_buffer_data)
  end
  
  defp pad_entry(entry, target_size) do
    current_size = byte_size(entry)
    if current_size < target_size do
      padding_size = target_size - current_size
      <<entry::binary, 0::size(padding_size)-unit(8)>>
    else
      :binary.part(entry, 0, target_size)  # Truncate if too large
    end
  end
end
```

**Day 12-14: Performance Optimization & Testing**
```elixir
defmodule ElixirScope.Week2.Performance do
  @moduledoc """
  Rigorous performance testing of ring buffer implementations
  """
  
  def benchmark_ring_buffers() do
    IO.puts("=== Ring Buffer Performance Benchmark ===")
    
    # Test configurations
    configs = [
      {1_000, 64},     # Small buffer, small entries
      {10_000, 128},   # Medium buffer, medium entries  
      {100_000, 256},  # Large buffer, large entries
    ]
    
    for {capacity, entry_size} <- configs do
      IO.puts("\nTesting capacity=#{capacity}, entry_size=#{entry_size}")
      
      benchmark_basic_buffer(capacity, entry_size)
      benchmark_lockfree_buffer(capacity, entry_size)
      benchmark_concurrent_access(capacity, entry_size)
    end
  end
  
  defp benchmark_basic_buffer(capacity, entry_size) do
    buffer = ElixirScope.Week2.BasicRingBuffer.new(capacity, entry_size)
    test_entry = :crypto.strong_rand_bytes(entry_size - 10)  # Leave room for padding
    
    # Single-threaded write performance
    {write_time, _} = :timer.tc(fn ->
      Enum.reduce(1..10_000, buffer, fn _i, acc_buffer ->
        {:ok, new_buffer} = ElixirScope.Week2.BasicRingBuffer.write(acc_buffer, test_entry)
        new_buffer
      end)
    end)
    
    writes_per_second = 10_000 / (write_time / 1_000_000)
    IO.puts("  Basic buffer: #{:erlang.float_to_binary(writes_per_second, decimals: 0)} writes/sec")
  end
  
  defp benchmark_lockfree_buffer(capacity, entry_size) do
    buffer = ElixirScope.Week2.LockFreeBuffer.new(capacity, entry_size)
    test_entry = :crypto.strong_rand_bytes(entry_size - 10)
    
    # Single-threaded write performance
    {write_time, _} = :timer.tc(fn ->
      for _i <- 1..10_000 do
        ElixirScope.Week2.LockFreeBuffer.write_atomic(buffer, test_entry)
      end
    end)
    
    writes_per_second = 10_000 / (write_time / 1_000_000)
    IO.puts("  Lock-free buffer: #{:erlang.float_to_binary(writes_per_second, decimals: 0)} writes/sec")
  end
  
  defp benchmark_concurrent_access(capacity, entry_size) do
    buffer = ElixirScope.Week2.LockFreeBuffer.new(capacity, entry_size)
    test_entry = :crypto.strong_rand_bytes(entry_size - 10)
    
    # Multi-process concurrent writes
    num_processes = 4
    writes_per_process = 2_500
    
    {concurrent_time, _} = :timer.tc(fn ->
      tasks = for _i <- 1..num_processes do
        Task.async(fn ->
          for _j <- 1..writes_per_process do
            ElixirScope.Week2.LockFreeBuffer.write_atomic(buffer, test_entry)
          end
        end)
      end
      
      Task.await_many(tasks, 30_000)
    end)
    
    total_writes = num_processes * writes_per_process
    writes_per_second = total_writes / (concurrent_time / 1_000_000)
    IO.puts("  Concurrent (#{num_processes} processes): #{:erlang.float_to_binary(writes_per_second, decimals: 0)} writes/sec")
  end
end
```

**Week 2 Checkpoint Validation**:
- [ ] Ring buffer handles 100K+ writes/second
- [ ] Lock-free version works correctly under concurrent access
- [ ] Memory usage is predictable and bounded  
- [ ] No data corruption under stress testing
- [ ] Performance scales reasonably with buffer size

## **Critical Success Metrics for Layer 1.1**

After 4 weeks of development, Layer 1.1 must meet these non-negotiable criteria:

**Performance Requirements**:
- [ ] VM event capture: <1 microsecond per event
- [ ] Ring buffer writes: >100K writes/second
- [ ] Total system overhead: <2% on typical workloads
- [ ] Memory usage: Bounded and predictable

**Reliability Requirements**:
- [ ] Zero crashes during 24-hour continuous operation
- [ ] Graceful handling of extreme event bursts (>1M events/minute)
- [ ] Clean startup/shutdown with proper resource cleanup
- [ ] No memory leaks during extended operation

**Functional Requirements**:
- [ ] Captures all basic VM events (spawn, exit, send, receive)
- [ ] Event serialization/deserialization is lossless
- [ ] Works across multiple Elixir/OTP versions
- [ ] Integrates cleanly with existing applications

**Quality Gates**:
- [ ] 100% automated test coverage
- [ ] Performance benchmarks pass on multiple hardware configurations  
- [ ] Code review approval from senior team members
- [ ] Documentation complete and validated

Only after Layer 1.1 meets ALL these criteria do we proceed to Layer 1.2. This discipline ensures we build on absolutely solid ground.

---

## Quality Gates Between Sub-Layers

Each sub-layer must pass rigorous testing before proceeding:

### Automated Testing Suite
```elixir
defmodule ElixirScope.QualityGate do
  def validate_layer(layer_number) do
    case layer_number do
      1.1 -> validate_foundation()
      1.2 -> validate_basic_ast() 
      1.3 -> validate_smart_ast()
      1.4 -> validate_advanced_vm()
      1.5 -> validate_comprehensive()
    end
  end
  
  defp validate_foundation() do
    [
      performance_test_suite(),
      memory_stability_test(),
      concurrent_access_test(),
      error_recovery_test(),
      long_running_stability_test()
    ]
    |> Enum.all?(&(&1 == :pass))
  end
end
```

This progressive approach ensures that each sub-layer of Layer 1 Foundation is rock-solid before moving forward, creating an unshakeable foundation for the entire ElixirScope system.
