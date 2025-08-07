defmodule TestUtils do
  @moduledoc false
  def build_license_key(organization_id, plan, expires_at, seats) do
    data =
      %{
        id: UXID.generate!(prefix: "lic"),
        organization_id: organization_id,
        plan: plan,
        expires_at: expires_at,
        free_trial: false,
        seats: seats
      }
      |> Jason.encode!()
      |> :zlib.zip()

    private_key = Base.decode64!("LyTT51w4kOYxWLQ2zUUNi7NaovQwdKfeAczzqGGHbL8=")
    signature = :crypto.sign(:eddsa, nil, data, [private_key, :ed25519])
    data_size = byte_size(data)

    Base.encode64(<<data_size::unsigned-integer-32, data::binary, signature::binary>>)
  end
end
