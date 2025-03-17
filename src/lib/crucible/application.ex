defmodule Crucible.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger

  use Application

  #
  #
  #
  #
  @impl true
  def start(_type, _args) do
    # Start Dynamic supervisor
    {:ok, pid} =
      DynamicSupervisor.start_link(strategy: :one_for_one, name: Crucible.DynamicSupervisor)

    # get config from src/config
    Application.fetch_env!(:crucible, :endpoints)
    # Check if there are any endpoints
    |> case do
      # no endpoints.
      [] ->
        Logger.critical("No endpoints provided in src/config.config.exs. This error is fatal.")
        raise "No endpoints provided in src/config.config.exs. This error is fatal."

      # is list containing endpoints - return list.
      list ->
        list
    end
    # Create children endpoint trees
    # One tree per endpoint
    |> Enum.map(&build_endpoint/1)
    |> List.flatten()
    # Add each child to dynamic supervisor
    |> Enum.map(fn srv -> DynamicSupervisor.start_child(pid, srv) end)

    #
    {:ok, pid}
  end

  #
  #
  #
  # Create socket+taskSup per config
  # # {<:endpoint_name_atom>, :tcp | :udp, <inbound-port(integer)>,  <"ip string"> , <outbound-port(integer)>, :single | :dynamic}
  def build_endpoint({name, proto, in_port, target, out_port, mode}) when is_atom(name) do
    # Decide which children services will be used.
    # Endpoint name to string
    name_str = Atom.to_string(name)
    # Ip string to struct
    {:ok, ipAddr} = ~c"#{target}" |> :inet.parse_address()
    # Generate task supervisor
    # Task Supervisor mode
    {taskSupSpec, taskSupName} =
      case mode do
        # Single pid for supervisor
        :single ->
          srv_name = String.to_atom(name_str <> "_task_sup")
          {{Task.Supervisor, name: srv_name}, srv_name}

        # DistributionPartition + Task Supervisor
        :dynamic ->
          srv_name = String.to_atom(name_str <> "_dyn_task_sup")
          {{PartitionSupervisor, child_spec: Task.Supervisor, name: srv_name}, srv_name}
      end

    # Socket protocol type
    socketSpec =
      case proto do
        # TCP Socket
        :tcp ->
          {Crucible.Tcp,
           name: String.to_atom(name_str <> "_tcp_socket"),
           task_sup: {taskSupName, mode},
           in_port: in_port,
           target: ipAddr,
           out_port: out_port}

        # UDP Socket
        :udp ->
          #
          raise "UDP Protocol has not been implemented yet. Please use ':tcp' instead."

          {Crucible.Udp,
           name: String.to_atom(name_str <> "_udp_socket"),
           task_sup: {taskSupName, mode},
           in_port: in_port,
           target: ipAddr,
           out_port: out_port}

        # Catch
        invalid ->
          raise "Invalid protocol (#{invalid}) type provided for endpoint (#{name}) "
      end

    # children for higher-level Super-visor
    [
      socketSpec,
      taskSupSpec
    ]
  end
end
