# Crucible
TCP/UDP Proxy and Load balancer. Written entirely with the Elixir and Erlang Standard library.


## How to setup

### Download via git

```git
git clone http://github.com/jimurrito/crucible.git
```

### Endpoint config

Under `src/config` we can add our desired endpoint configuration.

*Example*
```elixir
config :crucible,
  endpoints: [
    {:test_endpoint, :tcp, 8080, "127.0.0.1", 8181, :single},
    {:test_endpoint2, :tcp, 8081, "127.0.0.1", 8181, :dynamic}
  ]
```

Each record above represents an endpoint that will be hosted by Crucible. Here is a break down of the record:

```Elixir
# Example:
{
    :test_endpoint, 
    :tcp, 
    8080,  
    127.0.0.1 , 
    8181, 
    :single
}

# Spec:
{
    Atom,                 # Name
    :tcp | :udp,          # protocol
    Integer,              # Inbound Port
    String ,              # Target (Ipv4 Address ONLY as of now.)
    Integer,              # Outbound Port
    :single | :dynamic    # Worker Mode
}
```


| Parameter     | Spec              | Description                                                                                    |
| ------------- | ----------------- | ---------------------------------------------------------------------------------------------- |
| Name          | Atom              | Friendly name for the endpoint. Name must be an Atom. Example: ~~endpoint~~ => :endpoint.      |
| Protocol      | :tcp, :udp        | The layer 3 protocol that will be used by the endpoint.                                        |
| Inbound Port  | Integer (u16)     | Port that Crucible will listen on for the endpoint. Endpoints can not share ports.             |
| Target        | String (Ipv4)     | The IPv4 address of the target backend service.                                                |
| Outbound Port | Integer (u16)     | Port that Crucible will reach out to the target at.                                            |
| Worker Mode   | :single, :dynamic | Improves throughput at the cost of additional resources. See section on Worker Modes for more. |



### Start up

Once you have your endpoints configured, we can start the server up.
```bash
cd src/

mix           # Non-interactive mode   
iex -S mix    # Interactive mode via IEX  (Avoid for production use)
```


## Questions or Issues?
Open an issue on this repo.