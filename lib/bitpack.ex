defmodule Bitpack do
  @moduledoc """
  A `Bitpack` has characteristics of an array, but with the goal
  of striving to be as memory-efficient as possible.

  Only non-negative integers are currently supported.

  The size/length of a `Bitpack` does not need to be given, it will
  grow automatically, based on the highest index that it is inserted
  into. Indices need not be consecutive. Gaps between occupied indices
  have the value `0`.

  A `max_value` must be provided upon creation, and values that are
  inserted are not allowed to exceed that number.

  `Bitpack` implements the `Enumerable` protocol, so many of the
  functions found in the `Enum` module work with `Bitpack` too. Beware,
  however, that some `Enum` functions will have worse performance than
  similar `Bitpack` functions. For example, `Enum.at/2` with a `Bitpack`
  performs in O(n) time, while `Bitpack.get/2` is O(1).
  """

  @derive {Inspect, only: [:max_value]}

  defstruct [:bit_width, :bit_mask, :max_value, :data, :max_idx, :last_idx]

  @opaque bit_mask :: non_neg_integer()
  @opaque bit_width :: pos_integer()

  @type t :: %Bitpack{
          bit_width: bit_width(),
          bit_mask: bit_mask(),
          max_value: pos_integer(),
          data: non_neg_integer(),
          max_idx: integer(),
          last_idx: non_neg_integer()
        }

  @spec new(non_neg_integer()) :: t()
  def new(max_value) do
    bit_width = trunc(:math.floor(:math.log2(max_value)) + 1)
    bit_mask = Bitwise.bsl(1, bit_width) - 1

    %Bitpack{
      bit_width: bit_width,
      bit_mask: bit_mask,
      max_value: max_value,
      data: 0,
      last_idx: 0,
      max_idx: -1
    }
  end

  def set(%Bitpack{max_value: max_value}, _index, value) when value > max_value do
    raise ArgumentError, "value #{value} is greater than the maximum allowed value #{max_value}."
  end

  def set(%Bitpack{} = bitpack, index, value) do
    data = bitpack.data
    shift_count = index * bitpack.bit_width
    mask = Bitwise.bsl(bitpack.bit_mask, shift_count)

    data =
      Bitwise.bor(
        Bitwise.band(data, Bitwise.bnot(mask)),
        Bitwise.band(0, mask)
      )

    data = Bitwise.bor(data, Bitwise.bsl(value, shift_count))

    %Bitpack{
      bitpack
      | data: data,
        max_idx: max(bitpack.max_idx, index)
    }
  end

  def get(%Bitpack{} = bitpack, index) do
    offset = bitpack.bit_width * index
    Bitwise.band(Bitwise.bsr(bitpack.data, offset), bitpack.bit_mask)
  end
end
