defmodule KV.Bucket do
  @doc """
  Starts a new bucket.
  """

  # start_link is a process lifecycle callback for when link is initiated
  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(pid, key) do
    Agent.get(pid, fn map -> Map.get(map, key) end)
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(pid, key, val) do
    Agent.update(pid, fn map -> Map.put(map, key, val) end)
  end

  @doc """
  Deletes `key` from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(bucket, key) do
    # Code here is executed in the client
    Agent.get_and_update(bucket, fn map ->
      # Code here is executed in the server, must keep tradeoff in mind
      Map.pop(map, key)
    end)
  end

end