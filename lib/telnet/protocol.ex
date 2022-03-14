defmodule EchoServer.Telnet.Protocol do
  use GenServer

  @behaviour :ranch_protocol

  #rfc854 Telnet codes
  @iac 255 # Interpret as command
  @ga 249 # Go ahead

  # interpret as command
  @go_ahead <<@iac, @ga>>

  @greetings "Welcome to the Echoserver.\r\nType quit to disconnect.\r\n"

  # start_link is called for each new connection
  def start_link(ref, _socket, transport, opts) do
    IO.puts "Starting connection"
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end

  # implementation functions

  def init(_), do: nil # added here to avoid warning; dead code

  def init(ref, transport, _options) do # init here instead
    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, active: true)
    state = %{socket: socket, transport: transport}
    transport.send(state.socket, output(@greetings))
    :gen_server.enter_loop(__MODULE__, [], state)
  end

  # handle input

  def handle_info({:tcp, _socket, <<@iac>> <> _rest = iac}, state) do
    # client will stop receiving output. Why?
    IO.inspect iac
    {:noreply, state}
  end
  def handle_info({:tcp, socket, input}, %{transport: transport} = state) do
    IO.inspect input
    case input do
      "quit" <> _ -> send(self(), {:tcp_closed, socket})
      _ -> transport.send(socket, output(input))
    end
    {:noreply, state}
  end

  # terminate connection

  def handle_info({:tcp_closed, socket}, %{transport: transport} = state) do
    IO.puts "terminating connection"
    transport.close(socket)
    {:stop, :normal, state}
  end

  defp output(output) do
    IO.inspect output
    IO.iodata_to_binary([output, prompt(), @go_ahead])
  end

  defp prompt(), do: "> "

end
