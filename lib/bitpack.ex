defmodule Bitpack do
  defstruct [:bit_width, :bit_mask, :max_value, :data]

  def new(max_value) do
    bit_width = trunc(:math.floor(:math.log2(max_value)) + 1)
    # bit_mask = trunc(:math.pow(2, bit_width) - 1)
    bit_mask = Bitwise.bsl(1, bit_width) - 1

    %Bitpack{
      bit_width: bit_width,
      bit_mask: bit_mask,
      max_value: max_value,
      data: 0
    }
  end

  def set(bitpack, index, value) do
    data = bitpack.data
    shift_count = index * bitpack.bit_width
    mask = Bitwise.bsl(bitpack.bit_mask, shift_count)

    data =
      Bitwise.bor(
        Bitwise.band(data, Bitwise.bnot(mask)),
        Bitwise.band(0, mask)
      )

    data = Bitwise.bor(data, Bitwise.bsl(value, shift_count))

    %Bitpack{bitpack | data: data}
  end

  def get(bitpack, index) do
    offset = bitpack.bit_width * index
    Bitwise.band(Bitwise.bsr(bitpack.data, offset), bitpack.bit_mask)
  end
end
