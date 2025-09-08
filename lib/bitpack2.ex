defmodule Bitpack2 do
  defstruct [:bit_width, :max_value, :data, :max_idx, :last_idx]

  @opaque bit_width :: pos_integer()

  @type t :: %Bitpack2{
          bit_width: bit_width(),
          max_value: pos_integer(),
          data: non_neg_integer(),
          max_idx: integer(),
          last_idx: non_neg_integer()
        }

  def new(max_value) do
    %Bitpack2{
      bit_width: bit_width(max_value),
      max_value: max_value,
      data: <<0::size(64)>>,
      last_idx: 0,
      max_idx: -1
    }
  end

  # bits = for << i::1 <- <<18446744073709551615::64>> >>, do: i

  def set(%Bitpack2{} = bitpack, idx, value) do
    bit_width = bitpack.bit_width
    offset = idx * bit_width

    bitpack = grow(bitpack, offset + bit_width)

    <<head::size(offset), _slot::size(bit_width), tail::bits>> = bitpack.data

    bitpack
    |> Map.put(:data, <<head::size(offset), value::size(bit_width), tail::bits>>)
    |> Map.put(:max_idx, max(idx, bitpack.max_idx))
  end

  @spec append(Bitpack2.t(), non_neg_integer()) :: Bitpack2.t()
  def append(bitpack, value)

  def append(%Bitpack2{max_value: max_value}, value) when value > max_value do
    raise ArgumentError, "value #{value} is greater than the maximum allowed value #{max_value}."
  end

  def append(%Bitpack2{} = bitpack, value) do
    set(bitpack, bitpack.max_idx + 1, value)
  end

  def get(%Bitpack2{} = bitpack, idx) do
    bit_width = bitpack.bit_width
    <<_head::size(idx * bit_width), value::size(bit_width), _tail::bits>> = bitpack.data

    value
  end

  @spec from_list(list(non_neg_integer()), non_neg_integer()) :: Bitpack2.t()
  def from_list(seq, max_value) do
    max_value
    |> new()
    |> accumulate_from_list(seq)
  end

  defp accumulate_from_list(%Bitpack2{} = bitpack, [head]) do
    append(bitpack, head)
  end

  defp accumulate_from_list(%Bitpack2{} = bitpack, [head | tail]) do
    bitpack
    |> append(head)
    |> accumulate_from_list(tail)
  end

  defp bit_width(value) do
    value
    |> :math.log2()
    |> :math.floor()
    |> Kernel.+(1)
    |> trunc()
  end

  defp grow(%Bitpack2{} = bitpack, slot_idx) when slot_idx > bit_size(bitpack.data) do
    bitpack
    |> Map.put(:data, bitpack.data <> <<0::64>>)
    |> grow(slot_idx)
  end

  defp grow(%Bitpack2{} = bitpack, _slot_idx), do: bitpack
end
