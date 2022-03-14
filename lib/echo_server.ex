defmodule EchoServer do

  def start() do
    Supervisor.start_link([__MODULE__.Telnet.Listener], [strategy: :one_for_one])
  end
end
