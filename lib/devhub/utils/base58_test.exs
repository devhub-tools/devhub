defmodule Devhub.Utils.Base58Test do
  use ExUnit.Case, async: true

  import Devhub.Utils.Base58

  doctest Devhub.Utils.Base58

  describe "Testing encode function" do
    test "returns empty string when encoding an empty string" do
      assert "" == encode("")
    end

    test "returns base58 for the string foo" do
      assert "bQbp" == encode("foo")
    end

    test "converts any value to binary and then Base58 encodes it" do
      # Integer
      assert "4pa" == encode(23)
      assert "4pa" == encode("23")
      # Float
      assert "2JstGb" == encode(3.14)
      assert "2JstGb" == encode("3.14")
      # Atom
      assert "Cn8eVZg" == encode(:hello)
      assert "Cn8eVZg" == encode("hello")
    end

    test "returns z when binary is represented by 57" do
      assert "z" == encode(<<57>>)
    end

    test "add leading zeros as \"1\"" do
      assert "1112" == encode(<<0, 0, 0, 1>>)
    end

    test "encode empty string" do
      assert "Z" == encode(" ")
    end

    test "encode <<0>> returns 1" do
      assert "1" == encode(<<0>>)
    end

    test "encode <<0, 0, 0, 0, 0>> returns 11111" do
      assert "11111" == encode(<<0, 0, 0, 0, 0>>)
    end

    test "decode :atom" do
      assert :hello |> encode() |> decode() == {:ok, "hello"}
    end

    test "decode 11111 returns <<0, 0, 0, 0, 0>>" do
      assert {:ok, <<0, 0, 0, 0, 0>>} == decode("11111")
    end

    test "decode 11112 returns <<0, 0, 0, 0, 1>>" do
      assert {:ok, <<0, 0, 0, 0, 1>>} == decode("11112")
    end
  end
end
