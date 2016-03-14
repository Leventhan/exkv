# Basically an always-up-to-date service registry of processes
defmodule KV.Registry do
  use GenServer

  ## Client API
  # Starts a GenServer process linked to the current process.
  # http://elixir-lang.org/docs/stable/elixir/GenServer.html#start_link/3
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  # Looks up the process pid from a given process name
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  # Creates a bucket with a given process name and updates the registry
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Server Callbacks

  # initialization lifecycle callback, invoked when server is started
  # Receives the argument given to start_link() (:ok)
  # http://elixir-lang.org/docs/stable/elixir/GenServer.html#c:init/1
  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  # Handle looking up a bucket's pid given its name
  # _from refers to the process pid we received the request from (client)
  # the third (last) parameter is the new state of the genserver
  # handle_call is used for synchronous requests where you want to wait for a server reply
  def handle_call({:lookup, name}, _from, {names, _} = state) do
    {:reply, Map.fetch(names, name), state} # {status code, what is sent to client, new server state}
  end

  # Handle creating entries in bucket registry
  # handle_cast is used for async requests (fire and forget)
  def handle_cast({:create,name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KV.Bucket.Supervisor.start_bucket()
      ref = Process.monitor(pid) # Unlike bi-directional process links, a uni-directional monitor will not crash if the other side crashes
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end
  end

  # Handle listening to DOWN messages from downed buckets
  # handle_info is used for all other messages not sent via call or cast (i.e. via send)
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  # Catch all other messages, including the ones sent via send
  # Unexpected messages may arrive, so we define this catch-all clause
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end