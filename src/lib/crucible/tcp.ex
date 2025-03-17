defmodule Crucible.Tcp do
  @moduledoc """
  GenServer for the TCP Socket Listener
  """

  use GenServer
  require Logger

  #
  #
  #
  #
  #
  def start_link(
        name: name,
        task_sup: task_sup,
        in_port: in_port,
        target: target,
        out_port: out_port
      ) do
    GenServer.start_link(__MODULE__, [name, task_sup, in_port, target, out_port], name: name)
  end

  #
  #
  #
  #
  #
  @impl true
  def init([name, task_sup, in_port, target, out_port]) do
    Logger.info("[#{name}] Starting Endpoint listener on port (#{Integer.to_string(in_port)}).")

    # Start socket
    socket =
      :gen_tcp.listen(
        in_port,
        [:binary, active: false, reuseaddr: true]
      )
      |> case do
        # successfully opened socket
        {:ok, socket} ->
          Logger.debug("[#{name}] Now listening on port (#{Integer.to_string(in_port)}).")
          socket

        # Failed -> IP already in use
        {:error, :eaddrinuse} ->
          Logger.error(
            "[#{name}] Failed to bind listener socket to port [#{Integer.to_string(in_port)}] as the port is already in-use."
          )

          raise "Failed to bind listener socket to port [#{Integer.to_string(in_port)}] as the port is already in-use."

        # Failed -> Unmapped
        {:error, _error} ->
          Logger.error(
            "[#{name}] Unexpected error occurred while binding listener socket to port [#{Integer.to_string(in_port)}]."
          )

          raise "Unexpected error occurred while binding listener socket to port [#{Integer.to_string(in_port)}]."
      end

    # Start accepting requests
    GenServer.cast(name, :accept)

    # Return service as initialized.
    {:ok, [name: name, socket: socket, task_sup: task_sup, target: target, out_port: out_port]}
  end

  #
  #
  #
  #
  # Starts accepting requests.
  @impl true
  def handle_cast(:accept,
        name: name,
        socket: socket,
        task_sup: {taskSupName, mode},
        target: target,
        out_port: out_port
      ) do
    Logger.debug("[#{name}] Accepting new requests.")
    # FIFO accept the request from the socket buffer.
    {:ok, client_socket} = :gen_tcp.accept(socket)
    # Spawn working thread
    {:ok, pid} =
      case mode do
        # task sup in single mode
        :single ->
          Task.Supervisor.start_child(
            taskSupName,
            fn -> serve(client_socket, target, out_port) end
          )

        # task sup in dynamic mode
        :dynamic ->
          Task.Supervisor.start_child(
            {:via, PartitionSupervisor, {taskSupName, self()}},
            fn -> serve(client_socket, target, out_port) end
          )
      end

    # transfer ownership of the socket request to the worker PID
    :ok = :gen_tcp.controlling_process(client_socket, pid)

    # Recurse
    GenServer.cast(self(), :accept)

    # End cast
    {:noreply,
     [
       name: name,
       socket: socket,
       task_sup: {taskSupName, mode},
       target: target,
       out_port: out_port
     ]}
  end

  #
  #
  #
  #
  #
  # Serves requests
  defp serve(client_socket, target, out_port, acc \\ 0) do
    # Read data in socket
    :gen_tcp.recv(client_socket, 0)
    |> case do
      {:error, :closed} ->
        Logger.debug("Connection closed!")
        :closed_ungracefully

      {:ok, payload} ->
        Logger.debug("Client request (#{acc |> Integer.to_string()}) => [#{target |> :inet.ntoa()}]")
        #
        # relay to target
        :gen_tcp.connect(target, out_port, [:binary, active: false])
        |> case do
          # Connected to target
          {:ok, target_socket} ->
            # relay request
            :ok = :gen_tcp.send(target_socket, payload)
            # Await response
            # get payload response from server
            {:ok, payload} = :gen_tcp.recv(target_socket, 0)
            # Respond
            :gen_tcp.send(client_socket, payload)
            #
            # Loop - will only exit when client or server refuse to respond
            serve(client_socket, target, out_port, acc + 1)
            #
            # Done - cleanup
            :gen_tcp.close(target_socket)
            #
            :closed_gracefully

          # failed to connect to target
          error ->
            Logger.error(
              "Error occurred when attempting to connect to the target (#{:inet.ntoa(target)})."
            )

            IO.inspect({:target_error, %{target: target, msg: error}})
            :target_unreachable
        end
    end
  end
end
