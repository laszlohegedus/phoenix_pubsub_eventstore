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
  where `MyApp.EventStore` is configured separately based on the EventStore
  documentation.
  """
  @behaviour Phoenix.PubSub.Adapter
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:adapter_name])
  end

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

  def node_name(nil), do: node()
  def node_name(configured_name), do: configured_name

  def direct_broadcast(server, node_name, topic, message, dispatcher) do
    metadata = %{
      destination_node: to_string(node_name),
      source_node: to_string(node())
    }

    broadcast(server, topic, message, dispatcher, metadata)
  end

  def broadcast(server, topic, message, dispatcher, metadata \\ %{}) do
    metadata = Map.put(metadata, :dispatcher, dispatcher)

    GenServer.call(server, {:broadcast, topic, message, metadata})
  end

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

    case metadata do
      %{"destination_node" => destination_node} when destination_node != current_node ->
        # Direct broadcast and this is not the destination node.
        :ok

      %{"source" => ^id} ->
        # This node is the source, nothing to do, because local dispatch already
        # happened.
        :ok

      %{"dispatcher" => dispatcher} ->
        # Otherwise broadcast locally
        Phoenix.PubSub.local_broadcast(
          pubsub_name,
          topic,
          serializer.deserialize(data),
          String.to_existing_atom(dispatcher)
        )
    end
  end
end
