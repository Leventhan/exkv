# Basically an always-up-to-date service registry of processes
defmodule KV.Registry do
  use GenServer

  ## Client API
  # Starts a GenServer process linked to the current process.
  # http://elixir-lang.org/docs/stable/elixir/GenServer.html#start_link/3
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, [])
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
    {:ok, %{}}
  end

  # _from refers to the process pid we received the request from (client)
  # names refers to the current server state
  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names} # {status code, what is sent to client, new server state}
  end

  def handle_cast({:create,name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link()
      {:noreply, Map.put(names, name, bucket)}
    end
  end




end