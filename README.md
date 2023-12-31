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
    {:ex_buffer "~> 0.5.0"}
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

Once the `ExBuffer` has been started, we can insert items.

```elixir
ExBuffer.insert(:buffer, "foo")
ExBuffer.insert(:buffer, "bar")
```

And, once any of the configured conditions have been met, the `ExBuffer` will automatically flush.

```elixir
ExBuffer.insert(:buffer, "baz")
# `ExBuffer` flushes asynchronously and outputs ["foo", "bar", "baz"]
```

## Example

`ExBuffer` is designed to be highly customizable, allowing it to be used in any number of scenarios.
For example, we can use the `ExBuffer` behaviour to create a buffer with both a size limit and a time
limit:

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

We can easily start the `Buffer` process from above to see it in action:

```elixir
Buffer.start_link()

Buffer.insert("foo")
Buffer.insert("bar")
# Buffer flushes asynchronously and outputs ["foo", "bar"]

Buffer.insert("baz")
# After 30 seconds pass...
# Buffer flushes asynchronously and outputs ["baz"]
```

## Partitioning

In addition to it's customizability, `ExBuffer` also supports partitioning. Each `ExBuffer` partition
maintains it's own state and flushes independently:

```elixir
defmodule PartitionedBuffer do
  use ExBuffer

  def start_link(opts \\ []) do
    opts = Keyword.merge([max_length: 3, partitions: 2], opts)
    ExBuffer.start_link(__MODULE__, opts)
  end

  def insert(item) do
    ExBuffer.insert(__MODULE__, item)
  end

  @impl ExBuffer
  def handle_flush(data, opts) do
    partition = Keyword.get(opts, :partition)
    IO.inspect({partition, data})
  end
end
```

Again, we can easily start the `PartitionedBuffer` process from above to see it in action:

```elixir
PartitionedBuffer.start_link()

PartitionedBuffer.insert("foo")
PartitionedBuffer.insert("foo")
PartitionedBuffer.insert("bar")
PartitionedBuffer.insert("bar")
PartitionedBuffer.insert("baz")
# Partition 0 flushes asynchronously and outputs {0, ["foo", "bar", "baz"]}

PartitionedBuffer.insert("baz")
# Partition 1 flushes asynchronously and outputs {1, ["foo", "bar", "baz"]}
```

It's important to note that `ExBuffer` partitions are intended to be used primarily to split work, not
to distinguish flush behavior. Conceptually, each partition of a particular `ExBuffer` should flush in
the same way.
