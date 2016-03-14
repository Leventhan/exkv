# Basically an always-up-to-date service registry of processes
defmodule KV.Registry do
  use GenServer

  ## Client API
  # Starts a GenServer process linked to the current process.
  # http://elixir-lang.org/docs/stable/elixir/GenServer.html#start_link/3
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  # Looks up the process pid from a given process name
  def lookup(server, name) when is_atom(server) do
    # Lookup is now done directly in ETS, without accessing the server
    case :ets.lookup(server, name) do
      [{^name, bucket}] -> {:ok, bucket}
      [] -> :error
    end
  end

  # Creates a bucket with a given process name and updates the registry
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Server Callbacks

  # initialization lifecycle callback, invoked when server is started
  # Receives the argument given to start_link() (:ok)
  # http://elixir-lang.org/docs/stable/elixir/GenServer.html#c:init/1
  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  # Handle creating entries in bucket registry
  # handle_cast is used for async requests (fire and forget)
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket()
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  # Handle listening to DOWN messages from downed buckets
  # handle_info is used for all other messages not sent via call or cast (i.e. via send)
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  # Catch all other messages, including the ones sent via send
  # Unexpected messages may arrive, so we define this catch-all clause
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end