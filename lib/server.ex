defmodule TCPServer do
  def start_server(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    IO.puts("Server listening on port #{port}...")
    accept_loop(socket)
  end

  defp accept_loop(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    spawn(fn -> handle_client(client_socket) end)
    accept_loop(socket)
  end

  defp handle_client(socket) do
    # state = Stench.Eval.eval(tree)

    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        IO.puts("Received data: #{data}")
        # Here you can process the data and send a response
        {:ok, pid} = StringIO.open("")
        Application.put_env(:stench, :buffer, pid)
        s = data |> Stench.CLI.eval() |> inspect()
        Application.put_env(:stench, :buffer, :stdout)
        out_ary = StringIO.contents(pid) |> Tuple.to_list()
        out_len = Enum.count(out_ary)

        out = out_ary |> Enum.join()
        :gen_tcp.send(socket, out <> "\n" <> s)
        handle_client(socket)

      {:error, reason} ->
        IO.puts("Client disconnected: #{reason}")
    end
  end
end

# To run:
# TCPServer.start_server(4040)
