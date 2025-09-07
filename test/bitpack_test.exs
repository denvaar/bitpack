defmodule BitpackTest do
  use ExUnit.Case

  require Integer

  import ExUnit.CaptureIO

  doctest Bitpack

  describe "Bitpack.new/1" do
    test "correct bit width is chosen based on max value" do
      assert %Bitpack{bit_width: 1} = Bitpack.new(1)
      assert %Bitpack{bit_width: 2} = Bitpack.new(2)
      assert %Bitpack{bit_width: 2} = Bitpack.new(3)
      assert %Bitpack{bit_width: 3} = Bitpack.new(4)
      assert %Bitpack{bit_width: 3} = Bitpack.new(5)
      assert %Bitpack{bit_width: 3} = Bitpack.new(6)
      assert %Bitpack{bit_width: 3} = Bitpack.new(7)
      assert %Bitpack{bit_width: 16} = Bitpack.new(32768)
      assert %Bitpack{bit_width: 64} = Bitpack.new(9_223_372_036_854_775_808)
    end

    test "correct bit mask is chosen based on max value" do
      assert %Bitpack{bit_mask: 1} = Bitpack.new(1)
      assert %Bitpack{bit_mask: 3} = Bitpack.new(2)
      assert %Bitpack{bit_mask: 63} = Bitpack.new(32)

      assert %Bitpack{bit_mask: 9_223_372_036_854_775_807} =
               Bitpack.new(4_611_686_018_427_387_904)
    end
  end

  describe "Bitpack.set/3 and Bitpack.get/2" do
    test "able to set values at given index and then retrieve them" do
      values = [9, 20, 22, 100, 1, 50, 45, 44, 27, 1, 1, 1, 99, 2]

      bitpack =
        for {n, idx} <- Enum.with_index(values), reduce: Bitpack.new(100) do
          bitpack -> Bitpack.set(bitpack, idx, n)
        end

      for {n, idx} <- Enum.with_index(values), reduce: bitpack do
        bitpack ->
          assert n == Bitpack.get(bitpack, idx)
          bitpack
      end
    end

    test "able to set lots of values" do
      max_value = 100_000
      values = 1..max_value

      bitpack =
        for {n, idx} <- Enum.with_index(values), reduce: Bitpack.new(max_value) do
          bitpack -> Bitpack.set(bitpack, idx, n)
        end

      for {n, idx} <- Enum.with_index(values), reduce: bitpack do
        bitpack ->
          assert n == Bitpack.get(bitpack, idx)
          bitpack
      end
    end

    test "binary values" do
      range = 0..10

      bitpack =
        for n <- range, reduce: Bitpack.new(1) do
          bitpack ->
            if Integer.is_even(n) do
              Bitpack.append(bitpack, 0)
            else
              Bitpack.append(bitpack, 1)
            end
        end

      assert "01010101010" = Enum.join(bitpack, "")
    end
  end

  describe "Bitpack.append/2" do
    test "appends values" do
      Bitpack.new(100)
      |> Bitpack.append(100)
      |> tap(fn bitpack -> assert 100 = bitpack.data end)
      |> Bitpack.append(100)
      |> tap(fn bitpack -> assert 12900 = bitpack.data end)
      |> Bitpack.append(100)
      |> tap(fn bitpack -> assert 1_651_300 = bitpack.data end)
    end
  end

  describe "Enumerable.reduce/3" do
    test "empty" do
      assert [] = Enum.map(Bitpack.new(10), & &1)
    end

    test "consecutive indices" do
      bitpack =
        Enum.reduce(1..10, Bitpack.new(10), fn n, bitpack ->
          Bitpack.set(bitpack, n - 1, n)
        end)

      assert [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] = Enum.map(bitpack, & &1)
    end

    test "non-consecutive indices" do
      bitpack =
        Bitpack.new(10)
        |> Bitpack.set(9, 1)
        |> Bitpack.set(0, 4)
        |> Bitpack.set(5, 10)

      assert [4, 0, 0, 0, 0, 10, 0, 0, 0, 1] = Enum.map(bitpack, & &1)
    end

    test "iterates in from lowest to highest index" do
      bitpack =
        Bitpack.new(10)
        |> Bitpack.set(9, 1)
        |> Bitpack.set(0, 4)
        |> Bitpack.set(5, 10)

      io_output =
        capture_io(fn ->
          for n <- bitpack do
            IO.puts(n)
          end
        end)

      assert "4\n0\n0\n0\n0\n10\n0\n0\n0\n1\n" = io_output
    end
  end
end
