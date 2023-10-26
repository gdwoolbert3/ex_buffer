defmodule ExBuffer.Buffer do
  @moduledoc false

  defstruct [
    :flush_callback,
    :flush_meta,
    :max_length,
    :max_size,
    :size_callback,
    :timeout,
    buffer: [],
    length: 0,
    size: 0,
    timer: nil
  ]

  @type t :: %__MODULE__{}

  @flush_callback_arity 2
  @size_callback_arity 1

  ################################
  # Public API
  ################################

  @doc false
  @spec flush_callback_arity :: non_neg_integer()
  def flush_callback_arity, do: @flush_callback_arity

  @doc false
  @spec insert(t(), term()) :: {:flush, t()} | {:cont, t()}
  def insert(buffer, item) do
    buffer = %{
      buffer
      | buffer: [item | buffer.buffer],
        length: buffer.length + 1,
        size: buffer.size + buffer.size_callback.(item)
    }

    if flush?(buffer), do: {:flush, buffer}, else: {:cont, buffer}
  end

  @doc false
  @spec items(t()) :: list()
  def items(buffer), do: Enum.reverse(buffer.buffer)

  @doc false
  @spec new(keyword()) :: {:ok, t()} | {:error, ExBuffer.error()}
  def new(opts) do
    with {:ok, flush_callback} <- get_flush_callback(opts),
         {:ok, size_callback} <- get_size_callback(opts),
         {:ok, max_length} <- get_max_length(opts),
         {:ok, max_size} <- get_max_size(opts),
         {:ok, timeout} <- get_timeout(opts) do
      buffer = %__MODULE__{
        flush_callback: flush_callback,
        flush_meta: Keyword.get(opts, :flush_meta),
        max_length: max_length,
        max_size: max_size,
        size_callback: size_callback,
        timeout: timeout
      }

      {:ok, buffer}
    end
  end

  @doc false
  @spec refresh(t(), reference() | nil) :: t()
  def refresh(buffer, timer \\ nil) do
    %{buffer | buffer: [], length: 0, size: 0, timer: timer}
  end

  @doc false
  @spec size_callback_arity :: non_neg_integer()
  def size_callback_arity, do: @size_callback_arity

  ################################
  # Private API
  ################################

  defp get_flush_callback(opts) do
    case Keyword.get(opts, :flush_callback) do
      nil -> {:ok, nil}
      callback -> validate_callback(callback, @flush_callback_arity)
    end
  end

  defp get_size_callback(opts) do
    opts
    |> Keyword.get(:size_callback, &item_size/1)
    |> validate_callback(@size_callback_arity)
  end

  defp get_max_length(opts), do: validate_limit(Keyword.get(opts, :max_length, :infinity))
  defp get_max_size(opts), do: validate_limit(Keyword.get(opts, :max_size, :infinity))
  defp get_timeout(opts), do: validate_limit(Keyword.get(opts, :buffer_timeout, :infinity))

  defp validate_callback(fun, arity) when is_function(fun, arity), do: {:ok, fun}
  defp validate_callback(_, _), do: {:error, :invalid_callback}

  defp validate_limit(:infinity), do: {:ok, :infinity}
  defp validate_limit(limit) when is_integer(limit) and limit >= 0, do: {:ok, limit}
  defp validate_limit(_), do: {:error, :invalid_limit}

  defp item_size(item) when is_bitstring(item), do: byte_size(item)

  defp item_size(item) do
    item
    |> :erlang.term_to_binary()
    |> byte_size()
  end

  defp flush?(buffer) do
    exceeds?(buffer.length, buffer.max_length) or exceeds?(buffer.size, buffer.max_size)
  end

  defp exceeds?(_, :infinity), do: false
  defp exceeds?(num, max), do: num >= max
end