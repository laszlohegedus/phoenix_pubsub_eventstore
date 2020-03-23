defmodule Phoenix.PubSub.EventStore do
  @moduledoc """
  Phoenix PubSub adapter backed by EventStore.

  An example usage (add this to your supervision tree):
  ```elixir
  {Phoenix.PubSub,
    [name: MyApp.PubSub,
     adapter: Phoenix.PubSub.EventStore,
     eventstore: MyApp.EventStore]
  }
  ```
  where `MyApp.EventStore` is configured separately based on the `EventStore`
  documentation.

  An optional `:serializer` can be specified that is used for converting
  messages into structs that `EventStore` can handle. The default serializer
  is `Phoenix.PubSub.EventStore.Serializer.Base64`. Any module that implements
  `serialize/1` and `deserialize/1` may be used as long as they produce data
  that `EventStore` can handle.
  """
  @behaviour Phoenix.PubSub.Adapter
  use GenServer

  @metadata_fields [:source, :dispatcher, :destination_node, :source_node]

  @doc """
  Start the server

  This function is called by `Phoenix.PubSub`
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:adapter_name])
  end

  @doc false
  def init(opts) do
    send(self(), :subscribe)

    {:ok,
     %{
       id: UUID.uuid1(),
       pubsub_name: opts[:name],
       eventstore: opts[:eventstore],
       serializer: opts[:serializer] || Phoenix.PubSub.EventStore.Serializer.Base64
     }}
  end

  @doc false
  def node_name(nil), do: node()
  def node_name(configured_name), do: configured_name

  @doc false
  def direct_broadcast(server, node_name, topic, message, dispatcher) do
    metadata = %{
      destination_node: to_string(node_name),
      source_node: to_string(node())
    }

    broadcast(server, topic, message, dispatcher, metadata)
  end

  @doc false
  def broadcast(server, topic, message, dispatcher, metadata \\ %{}) do
    metadata = Map.put(metadata, :dispatcher, dispatcher)

    GenServer.call(server, {:broadcast, topic, message, metadata})
  end

  @doc false
  def handle_call(
        {:broadcast, topic, message, metadata},
        _from_pid,
        %{id: id, eventstore: eventstore, serializer: serializer} = state
      ) do
    event = %EventStore.EventData{
      event_type: to_string(serializer),
      data: serializer.serialize(message),
      metadata: Map.put(metadata, :source, id)
    }

    res = eventstore.append_to_stream(topic, :any_version, [event])

    {:reply, res, state}
  end

  @doc false
  def handle_info(:subscribe, %{eventstore: eventstore} = state) do
    eventstore.subscribe("$all")

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
         %{id: id, serializer: serializer, pubsub_name: pubsub_name} = _state
       ) do
    current_node = to_string(node())

    case convert_metadata_keys_to_atoms(metadata) do
      %{destination_node: destination_node}
      when not is_nil(destination_node) and destination_node != current_node ->
        # Direct broadcast and this is not the destination node.
        :ok

      %{source: ^id} ->
        # This node is the source, nothing to do, because local dispatch already
        # happened.
        :ok

      %{dispatcher: dispatcher} ->
        # Otherwise broadcast locally
        Phoenix.PubSub.local_broadcast(
          pubsub_name,
          topic,
          serializer.deserialize(data),
          maybe_convert_to_existing_atom(dispatcher)
        )
    end
  end

  defp convert_metadata_keys_to_atoms(metadata) do
    @metadata_fields
    |> Map.new(&{&1, Map.get(metadata, &1, Map.get(metadata, to_string(&1)))})
  end

  defp maybe_convert_to_existing_atom(string) when is_binary(string),
    do: String.to_existing_atom(string)

  defp maybe_convert_to_existing_atom(atom) when is_atom(atom), do: atom
end
