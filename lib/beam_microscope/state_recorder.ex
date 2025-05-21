defmodule BeamMicroscope.StateRecorder do
  @moduledoc """
  Provides a macro to automatically record GenServer state before and after `handle_call/3`.
  """

  defmacro __using__(_opts) do
    quote do
      # This will be executed in the context of the module using BeamMicroscope.StateRecorder

      # Store original handle_call/3 if it exists.
      # We need to check if it's defined because a GenServer might not implement all callbacks.
      @before_compile BeamMicroscope.StateRecorder

      # Define a new handle_call/3 that wraps the original one.
      defoverridable handle_call: 3 # Allows this definition to be overridden if needed, though unlikely here.

      # Default implementation if the user's module doesn't define handle_call/3
      # This is important to avoid compilation errors if the user's GenServer
      # doesn't have a handle_call/3. However, our use case implies they will.
      # For safety, we provide a default that would indicate it wasn't implemented.
      # def handle_call(request, from, state) do
      #   IO.inspect({__MODULE__, :unwrapped_handle_call, request, from, state}, label: "StateRecorder: Default handle_call (should be overridden by user or by our macro)")
      #   super(request, from, state) # Call the original GenServer's default
      # end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      # Check if the module has defined its own handle_call/3
      # The @behaviour GenServer attribute ensures that if handle_call/3 is defined,
      # it will be as a public function.
      # We rely on the fact that if they `use GenServer`, this function might exist.

      # To correctly wrap handle_call/3, we will define a new version of it
      # that calls the *original* user-defined version.
      # Elixir's `def` will redefine the function. We need to capture the old one.
      # This is tricky. A common approach is to rename the old one.
      # However, `defoverridable` and then defining it is cleaner.

      # Let's redefine handle_call/3 only if it's actually defined by the user.
      # The __using__ macro has already set `defoverridable handle_call: 3`.

      # If the module using this StateRecorder has defined `handle_call/3`,
      # we will now define our wrapper version.
      # If they haven't, this `def` will become the module's `handle_call/3`.
      # This means a GenServer that `use BeamMicroscope.StateRecorder` but doesn't
      # implement `handle_call/3` itself would still compile and run this logging version.
      # This is acceptable, as it would likely indicate an issue in the user's GenServer logic
      # if it receives a call it doesn't handle.

      def handle_call(request, from, state) do
        # Log state before
        BeamMicroscope.TraceDB.store_event(:genserver_state_pre_call, %{
          pid: self(),
          module: __MODULE__,
          request: request,
          from: from,
          state_before: state # Consider scrubbing sensitive data if necessary
        })

        # Call the original implementation.
        # Since we used `defoverridable` in `__using__` and are now defining `handle_call/3`,
        # `super` will refer to the definition that was active before this one.
        # If the user defined `handle_call/3`, `super` calls that.
        # If user did not, `super` calls `GenServer.handle_call/3` which is the default.
        original_result = super(request, from, state)

        # Determine the new state based on the GenServer's reply format
        new_state =
          case original_result do
            {:reply, _reply, new_state_val, _hibernate_or_timeout} -> new_state_val
            {:reply, _reply, new_state_val} -> new_state_val
            {:noreply, new_state_val, _hibernate_or_timeout} -> new_state_val
            {:noreply, new_state_val} -> new_state_val
            {:stop, _reason, _reply, new_state_val} -> new_state_val # Process stops, but this was its last state
            {:stop, _reason, new_state_val} -> new_state_val
            _ -> state # If result is not a standard GenServer reply that changes state, assume state is unchanged.
          end

        # Log state after
        BeamMicroscope.TraceDB.store_event(:genserver_state_post_call, %{
          pid: self(),
          module: __MODULE__,
          request: request, # Repetitive, but good for context
          original_result: original_result, # Or just the reply part
          state_after: new_state # Consider scrubbing
        })

        original_result # Return the original result
      end
    end
  end
end
