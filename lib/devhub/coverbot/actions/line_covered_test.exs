defmodule Devhub.Coverbot.Actions.LineCoveredTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "success" do
    coverage = %{
      22 => false,
      24 => false,
      25 => false,
      31 => true,
      33 => true,
      34 => true,
      36 => true,
      41 => true,
      45 => false,
      47 => false,
      48 => false,
      (50..52) => true,
      (52..52) => false,
      53 => false,
      55 => false,
      57 => false,
      64 => true,
      66 => true,
      68 => true,
      69 => true,
      135 => true,
      138 => true
    }

    assert Coverbot.line_covered?(coverage, 22) == false
    assert Coverbot.line_covered?(coverage, 31) == true
    assert Coverbot.line_covered?(coverage, 50) == true
    assert Coverbot.line_covered?(coverage, 51) == true
    assert Coverbot.line_covered?(coverage, 52) == false

    assert is_nil(Coverbot.line_covered?(coverage, 23))
  end
end
