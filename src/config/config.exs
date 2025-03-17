import Config

# Configuration for the endpoints.
# EXAMPLE:
# {<:endpoint_name_atom>, :tcp | :udp, <inbound-port(integer)>,  <"target-uri/ip string"> , <outbound-port(integer)>, :single | :dynamic}
config :crucible,
  endpoints: [
    # TCP test endpoints
    {:test_endpoint, :tcp, 8080, "127.0.0.1", 8181, :single},
    {:test_endpoint2, :tcp, 8081, "127.0.0.1", 8181, :dynamic}
  ]
