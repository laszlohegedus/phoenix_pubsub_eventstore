defmodule Phoenix.PubSub.EventStore do
  @moduledoc """
  Phoenix PubSub adapter backed by EventStore. Supervisor module.

  An example usage (add this to your supervision tree):
  ```elixir
  {Phoenix.PubSub.EventStore,
    [name: MyApp.PubSub, eventstore: MyApp.EventStore]}
  ```
  where `MyApp.EventStore` is configured separately based on the EventStore
  documentation.
  """
  use Supervisor

  def start_link(opts) do
    start_link(opts[:name], opts)
  end

  def start_link(name, opts) do
    supervisor_name = Module.concat(name, Supervisor)
    opts = Keyword.put_new(opts, :name, name)

    Supervisor.start_link(__MODULE__, opts, name: supervisor_name)
  end

  def init(opts) do
    pub_sub = opts[:name]
    scheduler_count = :erlang.system_info(:schedulers)
    pool_size = Keyword.get(opts, :pool_size, scheduler_count)
    node_name = opts[:node_name]

    dispatch_rules = [
      {:broadcast, Phoenix.PubSub.EventStore.Worker, [opts[:fastlane], pub_sub, pool_size]},
      {:direct_broadcast, Phoenix.PubSub.EventStore.Worker,
       [opts[:fastlane], pub_sub, pool_size]},
      {:node_name, __MODULE__, [node_name]}
    ]

    children = [
      supervisor(Phoenix.PubSub.LocalSupervisor, [pub_sub, pool_size, dispatch_rules]),
      worker(Phoenix.PubSub.EventStore.Worker, [pub_sub, opts])
    ]

    supervise(children, strategy: :rest_for_one)
  end

  def node_name(nil), do: node()
  def node_name(configured_name), do: configured_name
end
