# # eventually we will generate the organization as part of the seed when we auto add users to an organization
# organization_id = "org_01JGM94PXYRVN0"

# repo =
#   Devhub.Repo.insert!(%Devhub.Integrations.GitHub.Repository{
#     organization_id: organization_id,
#     name: "example",
#     owner: "devhub-tools",
#     default_branch: "main",
#     pushed_at: DateTime.truncate(DateTime.utc_now(), :second)
#   })

# Enum.each(1..10, fn _ ->
#   Devhub.Repo.insert!(%Devhub.Coverbot.Coverage{
#     organization_id: organization_id,
#     repository_id: repo.id,
#     is_for_default_branch: true,
#     sha: Ecto.UUID.generate(),
#     ref: "refs/heads/main",
#     covered: 65,
#     relevant: 42,
#     percentage: Decimal.new("65")
#   })
# end)
