defmodule Chlorine.Component.Bucket do
  use Agent

  def start_link(opts) do
    Agent.start_link(fn -> %{} end, opts)
  end

  def put(bucket, component_id, value) do
    Agent.update(bucket, &Map.put(&1, component_id, value))
  end

  def get(bucket, component_id) do
    Agent.get(bucket, &Map.get(&1, component_id))
  end

  def get(bucket) do
    # TODO: Might need to return the struct IDs anyway
    Agent.get(bucket, & &1)
  end

  def delete(bucket, component_id) do
    Agent.update(bucket, &Map.delete(&1, component_id))
  end
end
