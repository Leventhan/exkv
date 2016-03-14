defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, registry} = KV.Registry.start_link
    {:ok, registry: registry}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "test") == :error

    KV.Registry.create(registry, "test")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "test")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "test")
    {:ok, bucket} = KV.Registry.lookup(registry, "test")
    assert KV.Registry.lookup(registry, "test") != :error

    Agent.stop(bucket)
    assert KV.Registry.lookup(registry, "test") == :error
  end
end