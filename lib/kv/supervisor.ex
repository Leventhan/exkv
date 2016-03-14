defmodule KV.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(KV.Registry, [KV.Registry]),
      supervisor(KV.Bucket.Supervisor, [])
      # the Registry process is started with itself as the default argument
      # The above worker call runs: KV.Registry.start_link(KV.Registry)
    ]
    supervise(children, strategy: :rest_for_one)
  end
end