defmodule Bitpack3 do
  defstruct [:bit_width, :max_value, :data, :max_idx, :last_idx]

  @opaque bit_width :: pos_integer()

  @type t :: %Bitpack3{
          bit_width: bit_width(),
          max_value: pos_integer(),
          data: non_neg_integer(),
          max_idx: integer(),
          last_idx: non_neg_integer()
        }

  def new(max_value) do
    %Bitpack3{
      bit_width: bit_width(max_value),
      max_value: max_value,
      data: <<0>>,
      last_idx: 0,
      max_idx: -1
    }
  end

  # bits = for << i::1 <- <<18446744073709551615::64>> >>, do: i

  def set(%Bitpack3{} = bitpack, idx, value) do
    bit_width = bitpack.bit_width
    bit_offset = idx * bit_width

    bitpack = grow(bitpack, bit_offset + bit_width)

    # 1. Find which byte(s) the value belongs in.

    byte_offset_start = div(bit_offset, 8)

    byte_offset_end = div(bit_offset + bit_width, 8)

    target_bytes =
      :erlang.binary_part(
        bitpack.data,
        byte_offset_start,
        byte_offset_end - byte_offset_start + 1
      )

    # 2. Find the starting bit index.

    rel_bit_idx = relative_bit_index(bit_offset)

    <<head_bits::size(rel_bit_idx), _target_bits::size(bit_width), tail_bits::bits>> =
      target_bytes

    target_bytes = <<head_bits::size(rel_bit_idx), value::size(bit_width), tail_bits::bits>>

    head = :erlang.binary_part(bitpack.data, 0, byte_offset_start)

    tail =
      :erlang.binary_part(
        bitpack.data,
        byte_offset_start,
        max(
          0,
          byte_size(bitpack.data) - byte_size(head) -
            (8 * (byte_offset_end - byte_offset_start) + 1)
        )
      )

    bitpack
    |> Map.put(:data, <<head::binary, target_bytes::binary, tail::binary>>)
    |> Map.put(:max_idx, max(idx, bitpack.max_idx))
  end

  @spec append(Bitpack3.t(), non_neg_integer()) :: Bitpack3.t()
  def append(bitpack, value)

  def append(%Bitpack3{max_value: max_value}, value) when value > max_value do
    raise ArgumentError, "value #{value} is greater than the maximum allowed value #{max_value}."
  end

  def append(%Bitpack3{} = bitpack, value) do
    set(bitpack, bitpack.max_idx + 1, value)
  end

  def get(%Bitpack3{} = bitpack, idx) do
    bit_width = bitpack.bit_width
    bit_offset = idx * bit_width

    byte_offset_start = div(bit_offset, 8)
    byte_offset_end = div(bit_offset + bit_width, 8)

    target_bytes =
      :erlang.binary_part(
        bitpack.data,
        byte_offset_start,
        byte_offset_end - byte_offset_start + 1
      )

    rel_bit_idx = relative_bit_index(bit_offset)

    <<_head_bits::size(rel_bit_idx), target_bits::size(bit_width), _tail_bits::bits>> =
      target_bytes

    target_bits
  end

  @spec from_list(list(non_neg_integer()), non_neg_integer()) :: Bitpack3.t()
  def from_list(seq, max_value) do
    max_value
    |> new()
    |> accumulate_from_list(seq)
  end

  defp accumulate_from_list(%Bitpack3{} = bitpack, [head]) do
    append(bitpack, head)
  end

  defp accumulate_from_list(%Bitpack3{} = bitpack, [head | tail]) do
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

  defp grow(%Bitpack3{} = bitpack, slot_idx) when slot_idx >= bit_size(bitpack.data) do
    bitpack
    |> Map.put(:data, <<bitpack.data::bits, 0::8>>)
    |> grow(slot_idx)
  end

  defp grow(%Bitpack3{} = bitpack, _slot_idx), do: bitpack

  defp relative_bit_index(bit_offset), do: rem(bit_offset, 8)
end
