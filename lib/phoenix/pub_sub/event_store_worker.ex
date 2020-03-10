defmodule Phoenix.PubSub.EventStore.Worker do
  @moduledoc """
  Phoenix PubSub adapter backed by EventStore. Worker module.

  This module implements a GenServer that is responsible for publishing
  messages as events into an event store. It also subscribes to all topics
  and uses the local pubsub to distribute messages to local subscribers.
  """
  use GenServer

  def start_link(name, opts) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    send(self(), :subscribe)

    {:ok,
     %{
       event_store: opts[:eventstore],
       serializer: opts[:serializer] || Phoenix.PubSub.EventStore.Serializer.Base64
     }}
  end

  def node_name(nil), do: node()
  def node_name(configured_name), do: configured_name

  def direct_broadcast(fastlane, server, pool_size, node_name, from_pid, topic, message) do
    metadata = %{
      destination_node: to_string(node_name),
      source_node: to_string(node())
    }

    broadcast(fastlane, server, pool_size, from_pid, topic, message, metadata)
  end

  def broadcast(fastlane, server, pool_size, from_pid, topic, message, metadata \\ %{}) do
    broadcast_options = %{
      fastlane: fastlane,
      server: server,
      pool_size: pool_size,
      from_pid: encode_from_pid(from_pid)
    }

    GenServer.call(server, {:broadcast, topic, message, metadata, broadcast_options})
  end

  def handle_call(
        {:broadcast, topic, message, metadata, broadcast_options},
        _from_pid,
        %{event_store: event_store, serializer: serializer} = state
      ) do
    event = %EventStore.EventData{
      event_type: to_string(serializer),
      data: serializer.serialize(message),
      metadata: Map.put(metadata, :broadcast_options, broadcast_options)
    }

    res = event_store.append_to_stream(topic, :any_version, [event])

    {:reply, res, state}
  end

  def handle_info(:subscribe, %{event_store: event_store} = state) do
    event_store.subscribe("$all")

    {:noreply, state}
  end

  def handle_info({:subscribed, _subscription}, state) do
    {:noreply, state}
  end

  def handle_info({:events, events}, state) do
    Enum.each(events, &local_broadcast_event(&1, state))

    {:noreply, state}
  end

  defp local_broadcast_event(
         %EventStore.RecordedEvent{
           data: data,
           metadata: metadata,
           stream_uuid: topic
         },
         %{serializer: serializer} = _state
       ) do
    current_node = to_string(node())

    case metadata do
      %{"destination_node" => destination_node} when destination_node != current_node ->
        # Direct broadcast and this is not the destination node.
        :ok

      %{
        "broadcast_options" => %{
          "fastlane" => fastlane,
          "server" => server,
          "pool_size" => pool_size,
          "from_pid" => from_pid
        }
      } ->
        # Otherwise broadcast locally
        Phoenix.PubSub.Local.broadcast(
          decode_fastlane(fastlane),
          decode_server(server),
          pool_size,
          decode_from_pid(from_pid),
          topic,
          serializer.deserialize(data)
        )
    end
  end

  defp decode_fastlane(nil), do: nil
  defp decode_fastlane(module), do: String.to_existing_atom(module)

  defp decode_server(nil), do: nil
  defp decode_server(module), do: String.to_existing_atom(module)

  defp encode_from_pid(:none), do: "none"
  defp encode_from_pid(pid), do: to_string(:erlang.pid_to_list(pid))

  defp decode_from_pid("none"), do: :none
  defp decode_from_pid(pid_as_string), do: :erlang.list_to_pid(to_charlist(pid_as_string))
end
