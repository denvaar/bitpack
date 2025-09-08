defmodule Benchmark do
  def all(n) do
    build_sequence(n)
    random_access_read(n)
    random_access_write(n)
  end

  def build_sequence(n) do
    # input = Range.to_list(1..n)
    input = List.duplicate(10, n)

    Benchee.run(
      %{
        "build sequence :array" => fn ->
          _ = :array.from_list(input)
          :ok
        end,
        "build sequence tuple" => fn ->
          _ = List.to_tuple(input)
          :ok
        end,
        "build sequence Map" => fn ->
          _ = Map.new(Enum.with_index(input), fn {x, idx} -> {idx, x} end)
          :ok
        end,
        "build sequence Bitpack" => fn ->
          _ = Bitpack.from_list(input, n)
          :ok
        end,
        "build sequence Bitpack2" => fn ->
          _ = Bitpack2.from_list(input, n)
          :ok
        end
      },
      profile_after: true
    )

    :ok
  end

  def random_access_read(n) do
    input = List.duplicate(10, n)

    seq_array = :array.from_list(input)
    seq_tuple = List.to_tuple(input)
    seq_map = Map.new(Enum.with_index(List.duplicate(10, n)), fn {x, idx} -> {idx, x} end)
    seq_bitpack = Bitpack.from_list(input, 10)
    seq_bitpack2 = Bitpack2.from_list(input, 10)

    random_indices = Enum.shuffle(0..(n - 1))

    Benchee.run(
      %{
        "rand access read :array" => fn ->
          for idx <- random_indices do
            _ = :array.get(idx, seq_array)
          end

          :ok
        end,
        "rand access read tuple" => fn ->
          for idx <- random_indices do
            _ = elem(seq_tuple, idx)
          end

          :ok
        end,
        "rand access read Map" => fn ->
          for idx <- random_indices do
            _ = Map.get(seq_map, idx)
          end

          :ok
        end,
        "rand access read Bitpack" => fn ->
          for idx <- random_indices do
            _ = Bitpack.get(seq_bitpack, idx)
          end

          :ok
        end,
        "rand access read Bitpack2" => fn ->
          for idx <- random_indices do
            _ = Bitpack2.get(seq_bitpack2, idx)
          end

          :ok
        end
      },
      profile_after: true
    )

    :ok
  end

  def random_access_write(n) do
    seq_array = :array.new()
    seq_tuple = {}
    seq_map = %{}
    seq_bitpack = Bitpack.new(n)
    seq_bitpack2 = Bitpack2.new(n)

    random_indices = Enum.shuffle(0..(n - 1))

    Benchee.run(
      %{
        "rand access write :array" => fn ->
          for idx <- random_indices, reduce: seq_array do
            seq_array -> :array.set(idx, idx, seq_array)
          end

          :ok
        end,
        "rand access write tuple" => fn ->
          for idx <- random_indices, reduce: seq_tuple do
            seq_tuple ->
              length = tuple_size(seq_tuple)

              if idx > length do
                seq_tuple
                |> Tuple.to_list()
                |> Kernel.++(List.duplicate(0, idx - length))
                |> List.to_tuple()
                |> Tuple.insert_at(idx, idx)
              else
                Tuple.insert_at(seq_tuple, idx, idx)
              end
          end

          :ok
        end,
        "rand access write Map" => fn ->
          for idx <- random_indices, reduce: seq_map do
            seq_map -> Map.put(seq_map, idx, idx)
          end

          :ok
        end,
        "rand access write Bitpack" => fn ->
          for idx <- random_indices, reduce: seq_bitpack do
            seq_bitpack -> Bitpack.set(seq_bitpack, idx, idx)
          end

          :ok
        end,
        "rand access write Bitpack2" => fn ->
          for idx <- random_indices, reduce: seq_bitpack2 do
            seq_bitpack2 -> Bitpack2.set(seq_bitpack2, idx, idx)
          end

          :ok
        end
      },
      profile_after: true
    )

    :ok
  end
end
