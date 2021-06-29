defmodule Chlorine.ComponentBucketTest do
  use ExUnit.Case, async: true

  alias Chlorine.Component.Bucket

  @data %{test: :bar}

  setup do
    {:ok, bucket} = Bucket.start_link([])
    {:ok, %{bucket: bucket}}
  end

  test "stores and gets values by key", %{bucket: bucket} do
    id = 10

    Bucket.put(bucket, id, @data)
    assert Bucket.get(bucket, id) == @data
  end

  test "deletes a key from a bucket", %{bucket: bucket} do
    id = 10

    Bucket.put(bucket, id, @data)
    assert Bucket.get(bucket, id) == @data
    :ok = Bucket.delete(bucket, id)
    assert is_nil(Bucket.get(bucket, id))
  end

  test "returns nil if a key does not exist", %{bucket: bucket} do
    assert is_nil(Bucket.get(bucket, 170))
  end
end
