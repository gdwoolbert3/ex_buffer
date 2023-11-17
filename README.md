# ExBuffer

![CI](https://github.com/gdwoolbert3/ex_buffer/actions/workflows/ci.yml/badge.svg)
[![Package](https://img.shields.io/hexpm/v/ex_buffer.svg)](https://hex.pm/packages/ex_buffer)

An `ExBuffer` is a process that maintains a collection of items and flushes them once certain conditions have
been met.

## Installation

This package can be installed by adding `:ex_buffer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_buffer "~> 0.4.0"}
  ]
end
```

## Documentation

For additional documentation, see [HexDocs](https://hexdocs.pm/ex_buffer/readme.html).

## Getting Started

We can easily start an `ExBuffer` by adding it directly to a supervision tree.

```elixir
opts = [
  flush_callback: fn data, _ -> IO.inspect(data) end,
  max_length: 3,
  name: :buffer
]

children = [
  {ExBuffer, opts}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

Once the buffer has been started, we can insert items.

```elixir
ExBuffer.insert(:buffer, "foo")
ExBuffer.insert(:buffer, "bar")
```

And, once any of the configured conditions have been met, the buffer will automatically flush.

```elixir
ExBuffer.insert(:buffer, "baz")
# ExBuffer flushes asynchronously and outputs ["foo", "bar", "baz"]
```

## Examples

`ExBuffer` is designed to be highly customizable, allowing it to be used in any number of scenarios.

### Simple Buffer

For example, we can use the `ExBuffer` behaviour to create a buffer with both a size limit and a time limit.

```elixir
defmodule Buffer do
  use ExBuffer

  def start_link(opts \\ []) do
    opts = Keyword.merge([max_size: 8, buffer_timeout: 30_000], opts)
    ExBuffer.start_link(__MODULE__, opts)
  end

  def insert(item) do
    ExBuffer.insert(__MODULE__, item)
  end

  @impl ExBuffer
  def handle_flush(data, _opts) do
    IO.inspect(data)
  end

  @impl ExBuffer
  def handle_size(item) do
    byte_size(item) + 1
  end
end
```

We can easily start the `Buffer` process from above to see it in action.

```elixir
Buffer.start_link()

Buffer.insert("foo")
Buffer.insert("bar")
# Buffer flushes asynchronously and outputs ["foo", "bar"]

Buffer.insert("baz")
# After 30 seconds pass...
# Buffer flushes asynchronously and outputs ["baz"]
```

### Partitioned Buffer

Alternatively, we could also use `ExBuffer` in conjunction with Elixir's `PartitionSupervisor` to easily
create a partitioned buffer with dynamic flush behavior.

```elixir
defmodule PartitionedBuffer do
  use Supervisor

  def start_link(opts \\ []) do
    opts = Keyword.merge([max_length: 3], opts)
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def insert(item, partition) do
    ExBuffer.insert({:via, PartitionSupervisor, {:buffer, partition}}, item)
  end

  @impl Supervisor
  def init(opts) do
    part_sup_opts = [
      name: :buffer,
      child_spec: {ExBuffer, opts},
      partitions: 2,
      with_arguments: fn [opts], part ->
        flush_callback = fn data, _ -> handle_flush(data, part) end
        [Keyword.put(opts, :flush_callback, flush_callback)]
      end
    ]

    children = [
      {PartitionSupervisor, part_sup_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp handle_flush(data, partition) do
    IO.inspect({partition, data})
  end
end
```

We can easily start the `PartitionedBuffer` process from above to see it in action.

```elixir
PartitionedBuffer.start_link()

PartitionedBuffer.insert("foo", 0)
PartitionedBuffer.insert("foo", 1)
PartitionedBuffer.insert("bar", 0)
PartitionedBuffer.insert("bar", 1)
PartitionedBuffer.insert("baz", 0)
# Partition 0 flushes asynchronously and outputs {0, ["foo", "bar", "baz"]}

PartitionedBuffer.insert("baz", 1)
# Partition 1 flushes asynchronously and outputs {1, ["foo", "bar", "baz"]}
```
