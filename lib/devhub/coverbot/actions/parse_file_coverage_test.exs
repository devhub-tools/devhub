defmodule Devhub.Coverbot.Actions.ParseFileCoverageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot

  test "success" do
    coverage = %{
      "135" => true,
      "138" => true,
      "22" => false,
      "24" => false,
      "25" => false,
      "31" => true,
      "33" => true,
      "34" => true,
      "36" => true,
      "41" => true,
      "45" => false,
      "47" => false,
      "48" => false,
      "50.1,52.3" => true,
      "52.4,52.5" => false,
      "53" => false,
      "55" => false,
      "57" => false,
      "64" => true,
      "66" => true,
      "68" => true,
      "69" => true
    }

    assert %{
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
           } == Coverbot.parse_file_coverage(coverage)
  end
end
