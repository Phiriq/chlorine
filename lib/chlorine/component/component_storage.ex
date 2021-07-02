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
    res = if is_nil(bucket), do: nil, else: Bucket.get(bucket, component_id)

    {:reply, res, buckets}
  end

  @impl true
  def handle_call({:get, module}, _from, buckets) do
    bucket = Map.get(buckets, module)
    res = if is_nil(bucket), do: nil, else: Bucket.get(bucket)

    {:reply, res, buckets}
  end

  @impl true
  def handle_call({:put, module, component_id, value}, _from, buckets) do
    bucket = Map.get(buckets, module)

    res =
      if is_nil(bucket) do
        # If a bucket for this module doesn't exist, create it
        {:ok, bucket} = Bucket.start_link([])
        :ok = Bucket.put(bucket, component_id, value)
        Map.put(buckets, module, bucket)
      else
        # Otherwise just put the component into the bucket
        :ok = Bucket.put(bucket, component_id, value)
        buckets
      end

    {:reply, :ok, res}
  end

  @impl true
  def handle_call({:delete, module, component_id}, _from, buckets) do
    bucket = Map.get(buckets, module)

    res =
      unless is_nil(bucket) do
        :ok = Bucket.delete(bucket, component_id)
      else
        {:error, :component_not_found}
      end

    {:reply, res, buckets}
  end
end
