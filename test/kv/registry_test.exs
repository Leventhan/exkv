defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, _} = KV.Registry.start_link(context.test)
    {:ok, registry: context.test}
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

    # Do a call to ensure the registry processed the down message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "test") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "test")
    {:ok, bucket} = KV.Registry.lookup(registry, "test")

    # Stop bucket process with non-:normal reason
    Process.exit(bucket, :shutdown)

    # Wait until bucket process is dead
    ref = Process.monitor(bucket)
    assert_receive {:DOWN, ^ref, _, _, _}

    # Do a call to ensure the registry processed the down message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "test") == :error
  end




end