defimpl Enumerable, for: Bitpack2 do
  def count(%Bitpack2{max_idx: 0}), do: {:ok, 0}
  def count(%Bitpack2{max_idx: max_idx}), do: {:ok, max_idx + 1}

  def member?(_bitpack, _element), do: {:error, __MODULE__}

  def slice(_bitpack), do: {:error, __MODULE__}

  def reduce(_bitpack, {:halt, acc}, _fun), do: {:halted, acc}

  def reduce(%Bitpack2{} = bitpack, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(bitpack, &1, fun)}

  def reduce(%Bitpack2{max_idx: -1}, {:cont, acc}, _fun), do: {:done, acc}

  def reduce(%Bitpack2{last_idx: last_idx, max_idx: max_idx}, {:cont, acc}, _fun)
      when last_idx == max_idx + 1,
      do: {:done, acc}

  def reduce(%Bitpack2{} = bitpack, {:cont, acc}, fun) do
    value = Bitpack2.get(bitpack, bitpack.last_idx)

    bitpack
    |> Map.put(:last_idx, bitpack.last_idx + 1)
    |> reduce(fun.(value, acc), fun)
  end
end

defimpl Enumerable, for: Bitpack do
  def count(%Bitpack{max_idx: 0}), do: {:ok, 0}
  def count(%Bitpack{max_idx: max_idx}), do: {:ok, max_idx + 1}

  def member?(_bitpack, _element), do: {:error, __MODULE__}

  def slice(_bitpack), do: {:error, __MODULE__}

  def reduce(_bitpack, {:halt, acc}, _fun), do: {:halted, acc}

  def reduce(%Bitpack{} = bitpack, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(bitpack, &1, fun)}

  def reduce(%Bitpack{data: 0, max_idx: -1}, {:cont, acc}, _fun), do: {:done, acc}

  def reduce(%Bitpack{data: 0, last_idx: last_idx, max_idx: max_idx}, {:cont, acc}, _fun)
      when last_idx == max_idx + 1,
      do: {:done, acc}

  def reduce(%Bitpack{} = bitpack, {:cont, acc}, fun) do
    value = Bitpack.get(bitpack, bitpack.last_idx)

    data = bitpack.data
    shift_count = bitpack.last_idx * bitpack.bit_width
    mask = Bitwise.bsl(bitpack.bit_mask, shift_count)

    data =
      Bitwise.bor(
        Bitwise.band(data, Bitwise.bnot(mask)),
        Bitwise.band(0, mask)
      )

    data = Bitwise.bor(data, Bitwise.bsl(0, shift_count))
    bitpack = %Bitpack{bitpack | data: data, last_idx: bitpack.last_idx + 1}

    reduce(bitpack, fun.(value, acc), fun)
  end
end
