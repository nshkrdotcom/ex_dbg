defmodule ElixirScope.PhoenixTracker do
  @moduledoc """
  Provides Phoenix-specific tracing and monitoring.
  
  This module specializes in tracking Phoenix components such as:
  - HTTP request/response cycles
  - LiveView updates and events
  - Channel joins and messages
  - PubSub broadcasts
  """
  
  alias ElixirScope.TraceDB
  
  @doc """
  Configures Phoenix to trace all Endpoint-related activity.
  
  This is a high-level function that enables comprehensive tracing 
  of Phoenix components.
  """
  def setup_phoenix_tracing(_endpoint \\ nil) do
    # Trace Phoenix.PubSub
    trace_phoenix_pubsub()
    
    # Trace Phoenix Channels
    trace_phoenix_channels()
    
    # Trace Phoenix Controllers
    trace_phoenix_controllers()
    
    # Return success
    :ok
  end
  
  @doc """
  Stops Phoenix-specific tracing by detaching telemetry handlers.
  """
  def stop_phoenix_tracing do
    # Detach telemetry handlers
    :telemetry.detach("elixir-scope-phoenix-endpoint")
    :telemetry.detach("elixir-scope-phoenix-router")
    :telemetry.detach("elixir-scope-phoenix-channel-join")
    :telemetry.detach("elixir-scope-phoenix-socket")
    
    if Code.ensure_loaded?(Phoenix.LiveView) do
      :telemetry.detach("elixir-scope-phoenix-live-view-mount")
      :telemetry.detach("elixir-scope-phoenix-live-view-render")
      :telemetry.detach("elixir-scope-phoenix-live-view-handle-event")
    end
    
    :ok
  end
  
  @doc """
  Enables tracing for a specific Phoenix PubSub server.
  
  Use this to monitor all PubSub operations happening in a Phoenix app.
  """
  def track_pubsub(_pubsub_server) do
    # Not implemented yet
    :ok
  end
  
  # Telemetry event handlers
  
  def handle_endpoint_event(_event, measurements, metadata, _config) do
    # Record HTTP request events
    TraceDB.store_event(:phoenix, %{
      type: :http_request,
      conn: sanitize_conn(metadata.conn),
      status: Map.get(metadata, :status),
      duration: Map.get(measurements, :duration),
      timestamp: System.monotonic_time(),
      pid: self()
    })
  end
  
  def handle_router_event(_event, measurements, metadata, _config) do
    # Record router dispatch events
    TraceDB.store_event(:phoenix, %{
      type: :router_dispatch,
      route: Map.get(metadata, :route),
      path_info: Map.get(metadata, :path_info, []),
      plug: Map.get(metadata, :plug),
      plug_opts: sanitize_value(Map.get(metadata, :plug_opts)),
      duration: Map.get(measurements, :duration),
      timestamp: System.monotonic_time(),
      pid: self()
    })
  end
  
  def handle_channel_join_event(_event, measurements, metadata, _config) do
    # Record channel join events
    TraceDB.store_event(:phoenix, %{
      type: :channel_join,
      channel: Map.get(metadata, :channel),
      topic: Map.get(metadata, :topic),
      duration: Map.get(measurements, :duration),
      timestamp: System.monotonic_time(),
      pid: self()
    })
  end
  
  def handle_socket_event(_event, _measurements, metadata, _config) do
    # Record socket connected events
    TraceDB.store_event(:phoenix, %{
      type: :socket_connected,
      transport: Map.get(metadata, :transport),
      timestamp: System.monotonic_time(),
      pid: self()
    })
  end
  
  def handle_live_view_mount_event(_event, measurements, metadata, _config) do
    # Record LiveView mount events
    TraceDB.store_event(:phoenix, %{
      type: :live_view_mount,
      view: Map.get(metadata, :view),
      duration: Map.get(measurements, :duration),
      timestamp: System.monotonic_time(),
      pid: self()
    })
  end
  
  def handle_live_view_render_event(_event, measurements, metadata, _config) do
    # Record LiveView render events
    TraceDB.store_event(:phoenix, %{
      type: :live_view_render,
      view: Map.get(metadata, :view),
      duration: Map.get(measurements, :duration),
      timestamp: System.monotonic_time(),
      pid: self()
    })
  end
  
  def handle_live_view_event(_event, measurements, metadata, _config) do
    # Record LiveView handle_event events
    TraceDB.store_event(:phoenix, %{
      type: :live_view_event,
      view: Map.get(metadata, :view),
      event: Map.get(metadata, :event),
      duration: Map.get(measurements, :duration),
      timestamp: System.monotonic_time(),
      pid: self()
    })
  end
  
  # Helper functions
  
  defp sanitize_conn(conn) do
    # Extract only the needed parts of conn to avoid storing too much data
    %{
      request_path: conn.request_path,
      method: conn.method,
      remote_ip: sanitize_value(conn.remote_ip),
      status: conn.status,
      state: conn.state
    }
  end
  
  defp sanitize_value(value) do
    # Convert value to a safe string representation
    try do
      inspect(value, limit: 50, pretty: false)
    rescue
      _ -> "<<error inspecting value>>"
    end
  end
  
  # Private functions for different Phoenix components
  
  defp trace_phoenix_pubsub do
    # Set up PubSub tracing
    if Code.ensure_loaded?(Phoenix.PubSub) do
      # No specific telemetry events for PubSub yet
      # Future: Could monkey-patch PubSub modules
      :ok
    else
      :ok
    end
  end
  
  defp trace_phoenix_channels do
    # Set up Channels tracing
    if Code.ensure_loaded?(Phoenix.Channel) do
      :telemetry.attach(
        "elixir-scope-phoenix-channel-join",
        [:phoenix, :channel_join, :stop],
        &handle_channel_join_event/4,
        nil
      )
      
      # Socket events
      :telemetry.attach(
        "elixir-scope-phoenix-socket",
        [:phoenix, :socket_connected],
        &handle_socket_event/4,
        nil
      )
      :ok
    else
      :ok
    end
  end
  
  defp trace_phoenix_controllers do
    # Set up Controller tracing
    if Code.ensure_loaded?(Phoenix.Controller) do
      # HTTP request events
      :telemetry.attach(
        "elixir-scope-phoenix-endpoint",
        [:phoenix, :endpoint, :stop],
        &handle_endpoint_event/4,
        nil
      )
      
      # Router dispatch events
      :telemetry.attach(
        "elixir-scope-phoenix-router",
        [:phoenix, :router_dispatch, :stop],
        &handle_router_event/4,
        nil
      )
      
      # LiveView events if available
      if Code.ensure_loaded?(Phoenix.LiveView) do
        :telemetry.attach(
          "elixir-scope-phoenix-live-view-mount",
          [:phoenix, :live_view, :mount, :stop],
          &handle_live_view_mount_event/4,
          nil
        )
        
        :telemetry.attach(
          "elixir-scope-phoenix-live-view-render",
          [:phoenix, :live_view, :render, :stop],
          &handle_live_view_render_event/4,
          nil
        )
        
        :telemetry.attach(
          "elixir-scope-phoenix-live-view-handle-event",
          [:phoenix, :live_view, :handle_event, :stop],
          &handle_live_view_event/4,
          nil
        )
      end
      
      :ok
    else
      :ok
    end
  end
end 