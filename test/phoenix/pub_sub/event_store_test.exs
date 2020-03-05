defmodule Phoenix.PubSub.EventStoreTest do
  use ExUnit.Case

  @topic "test.topic"

  defmodule TestData do
    defstruct [:tag]
  end

  describe "subscriptions" do
    test "I can broadcast a message on a topic" do
      {:ok, _} = Phoenix.PubSub.EventStoreTest.TestApp.Application.start(nil, nil)

      subscribe_to(@topic)

      broadcast(@topic, %{hello: :world})

      assert_receive %{hello: :world}, 5000
      Process.sleep(5000)
    end
  end

  defp subscribe_to(topic) do
    Phoenix.PubSub.subscribe(EventStoreTest.PubSub, topic)
  end

  defp broadcast(topic, message) do
    Phoenix.PubSub.broadcast(EventStoreTest.PubSub, topic, message)
  end
end
