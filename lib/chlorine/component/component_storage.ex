defmodule Chlorine.Component.Storage do
  use GenServer

  alias Chlorine.Component.Bucket
  alias Chlorine.Component

  # API functions

  @spec get(Component.id()) :: Component.data()
  def get({module, component_id}) do
    GenServer.call(__MODULE__, {:get, module, component_id})
  end

  @spec get(module()) :: list(Component.data())
  def get(module) when is_atom(module) do
    GenServer.call(__MODULE__, {:get, module})
  end

  @spec put(Component.id(), Component.data()) :: :ok
  def put({module, component_id}, value) do
    GenServer.call(__MODULE__, {:put, module, component_id, value})
  end

  @spec delete(Component.id()) :: :ok
  def delete({module, component_id}) do
    GenServer.call(__MODULE__, {:delete, module, component_id})
  end

  # GenServer callbacks

  def start_link(opts \\ []) do
    # TODO: Make this dynamic
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_value) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, module, component_id}, _from, buckets) do
    bucket = Map.get(buckets, module)

    if is_nil(bucket) do
      {:reply, nil, buckets}
    else
      {:reply, Bucket.get(bucket, component_id), buckets}
    end
  end

  @impl true
  def handle_call({:get, module}, _from, buckets) do
    bucket = Map.get(buckets, module)

    if is_nil(bucket) do
      {:reply, nil, buckets}
    else
      {:reply, Bucket.get(bucket), buckets}
    end
  end

  @impl true
  def handle_call({:put, module, component_id, value}, _from, buckets) do
    bucket = Map.get(buckets, module)

    if is_nil(bucket) do
      {:ok, bucket} = Bucket.start_link([])
      Bucket.put(bucket, component_id, value)
      new_buckets = Map.put(buckets, module, bucket)

      {:reply, :ok, new_buckets}
    else
      Bucket.put(bucket, component_id, value)
      {:reply, :ok, buckets}
    end
  end

  @impl true
  def handle_call({:delete, module, component_id}, _from, buckets) do
    bucket = Map.get(buckets, module)
    Bucket.delete(bucket, component_id)
    {:reply, :ok, buckets}
  end
end
