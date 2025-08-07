service_ids = [
  "svc_01JF6XS3TBS9GRGSPR9G3NPXPC",
  "svc_01JF6XSH55KQD83AR9AP98W1K2",
  "svc_01JF6XSV3K1WYKVM1R1DP6Y4JJ"
]

1..500_000
|> Enum.flat_map(fn i ->
  time = DateTime.add(DateTime.utc_now(), -i * 10, :second)

  Enum.map(service_ids, fn service_id ->
    %{
      id: UXID.generate!(prefix: "chk"),
      organization_id: "org_01JF6XH98XPBM0",
      service_id: service_id,
      status: :success,
      status_code: 200,
      response_body: "Hello, world!",
      dns_time: 10,
      connect_time: 20,
      tls_time: 30,
      first_byte_time: 40,
      request_time: 100,
      time_since_last_check: 10_000,
      inserted_at: time,
      updated_at: time
    }
  end)
end)
|> Enum.chunk_every(1000)
|> Enum.each(&Devhub.Repo.insert_all(Devhub.Uptime.Schemas.Check, &1))
