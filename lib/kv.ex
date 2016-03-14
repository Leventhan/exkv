defmodule KV do
  use Application # this is an application callback module

  # Callback run on application start, there is also stop, load, etc.
  def start(_type, _args) do
    KV.Supervisor.start_link
  end
end
