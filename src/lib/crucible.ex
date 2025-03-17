defmodule Crucible do
  @moduledoc """
  low-level Layer 4 TCP/UDP proxy.


  Each endpoint is defined with a record. (EndpointConfig)
  {<:endpoint_name_atom>, :tcp | :udp, <inbound-port(integer)>,  <"target-uri/ip string"> , <outbound-port(integer)>, :single | :dynamic}

  Each endpoint gets its own socket PID + Task Supervisor.
  if last element in the config tuple is `:single` the task supervisor runs on a single PID. If set to ':dynamic', it will use a Distribution Partition.


  `config.ex`


  ```elixir
  config :crucible,
    endpoints: [<EndpointConfig>]
  ```
  """
end
