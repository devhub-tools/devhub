defmodule Devhub.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Devhub.Repo

  alias Devhub.Coverbot.TestReports.Schemas.TestRun.Info
  alias Devhub.QueryDesk.Schemas.DatabaseColumn
  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.QueryDesk.Schemas.QueryApproval

  def api_key_factory(attrs) do
    token = attrs[:token] || :crypto.strong_rand_bytes(32)
    <<selector::binary-size(16), verifier::binary-size(16)>> = token

    organization = attrs[:organization] || build(:organization)

    %Devhub.ApiKeys.Schemas.ApiKey{
      id: UXID.generate!(prefix: "key"),
      name: "Default",
      selector: selector,
      verify_hash: :crypto.hash(:sha256, verifier),
      expires_at: attrs[:expires_at],
      organization: organization,
      organization_id: organization.id,
      permissions: attrs[:permissions] || [:full_access]
    }
  end

  def organization_factory(attrs) do
    id = UXID.generate!(prefix: "org")
    expires_at = attrs[:license][:expires_at] || DateTime.add(DateTime.utc_now(), 30, :day)

    license_key =
      TestUtils.build_license_key(id, attrs[:license][:plan] || :querydesk, expires_at, [
        "github:#{id}",
        "invite:invite@devhub.tools"
      ])

    license =
      Map.merge(
        %{
          plan: :scale,
          base_price: Decimal.new(12),
          next_bill: Decimal.new(60),
          price_per_seat: Decimal.new(12),
          included_seats: 1,
          extra_seats: 4,
          key: license_key,
          expires_at: expires_at,
          renew: true,
          free_trial: false,
          products: [:coverbot, :dev_portal, :querydesk, :terradesk],
          has_payment_method: false
        },
        attrs[:license] || %{}
      )

    license = struct(Devhub.Users.Schemas.Organization.License, license)

    # ignore in merge_attributes
    attrs = Map.delete(attrs, :license)

    {_public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)

    %Devhub.Users.Schemas.Organization{
      id: id,
      name: "Default organization",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      license: license,
      onboarding: %{invites: true, git_import_started: true, git: true, done: true},
      installation_id: UXID.generate!(prefix: "it"),
      private_key: private_key
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def team_factory do
    %Devhub.Users.Team{
      name: "team name",
      id: UXID.generate!(prefix: "team"),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def team_member_factory do
    %Devhub.Users.TeamMember{
      id: UXID.generate!(prefix: "mbr")
    }
  end

  def organization_user_factory do
    %Devhub.Users.Schemas.OrganizationUser{
      id: UXID.generate!(prefix: "org_usr"),
      permissions: %{super_admin: false, manager: false, billing_admin: false},
      roles: [],
      pending: false
    }
  end

  def user_factory do
    %Devhub.Users.User{
      id: UXID.generate!(prefix: "usr"),
      external_id: Ecto.UUID.generate(),
      provider: "github",
      name: "John Doe",
      email: "#{Ecto.UUID.generate()}@devhub.tools",
      picture: "https://example.com/picture.jpg",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def integration_factory do
    %Devhub.Integrations.Schemas.Integration{
      id: UXID.generate!(prefix: "int"),
      organization: build(:organization),
      provider: :github,
      external_id: Ecto.UUID.generate()
    }
  end

  def ical_factory do
    %Devhub.Integrations.Schemas.Ical{
      id: UXID.generate!(prefix: "int"),
      link: "webcal://www.google.com/calendar/ical/en.usa%40holiday.calendar.google.com/public/basic.ics",
      title: "OOO",
      color: "red"
    }
  end

  def linear_user_factory do
    %Devhub.Integrations.Linear.User{
      id: UXID.generate!(prefix: "lin_usr"),
      external_id: Ecto.UUID.generate(),
      name: "michael"
    }
  end

  def linear_team_factory do
    %Devhub.Integrations.Linear.Team{
      id: UXID.generate!(prefix: "lin_tm"),
      external_id: Ecto.UUID.generate()
    }
  end

  def linear_issue_factory do
    %Devhub.Integrations.Linear.Issue{
      id: UXID.generate!(prefix: "lin_iss"),
      external_id: Ecto.UUID.generate(),
      identifier: "VEL-" <> Ecto.UUID.generate(),
      priority: 0,
      priority_label: "No Priority"
    }
  end

  def linear_label_factory do
    %Devhub.Integrations.Linear.Label{
      id: UXID.generate!(prefix: "lin_lbl"),
      external_id: Ecto.UUID.generate(),
      name: "tech debt",
      color: "blue",
      type: :feature
    }
  end

  def label_factory do
    %Devhub.Shared.Schemas.Label{
      id: UXID.generate!(prefix: "lbl"),
      name: "testing",
      color: "#F16F1B"
    }
  end

  def labeled_object_factory do
    %Devhub.Shared.Schemas.LabeledObject{
      id: UXID.generate!(prefix: "lbl_obj")
    }
  end

  def project_factory do
    %Devhub.Integrations.Linear.Project{
      id: UXID.generate!(prefix: "lin_prj"),
      name: "My project",
      external_id: Ecto.UUID.generate()
    }
  end

  def repository_factory do
    %Devhub.Integrations.GitHub.Repository{
      id: UXID.generate!(prefix: "repo"),
      name: "devhub",
      owner: "devhub-tools",
      default_branch: "main",
      pushed_at: ~U[2023-12-24 13:26:08Z]
    }
  end

  def pull_request_factory do
    %Devhub.Integrations.GitHub.PullRequest{
      id: UXID.generate!(prefix: "pr"),
      number: 1,
      title: "title",
      author: "michaelst",
      first_commit_authored_at: ~U[2023-12-24 12:00:00Z],
      opened_at: ~U[2024-01-02 13:26:08.003Z],
      state: "CLOSED"
    }
  end

  def pull_request_review_factory do
    %Devhub.Integrations.GitHub.PullRequestReview{
      id: UXID.generate!(prefix: "prr"),
      github_id: "112abc",
      author: "michaelst",
      reviewed_at: ~U[2024-02-01 12:00:00Z]
    }
  end

  def commit_factory do
    %Devhub.Integrations.GitHub.Commit{
      id: UXID.generate!(prefix: "cmit"),
      sha: 20 |> :crypto.strong_rand_bytes() |> Base.encode16() |> String.downcase(),
      message: "completed testing",
      authored_at: ~U[2016-05-24 13:26:08Z]
    }
  end

  def github_app_factory do
    private_key =
      :public_key.pem_encode([
        :public_key.pem_entry_encode(:RSAPrivateKey, :public_key.generate_key({:rsa, 3072, 65_537}))
      ])

    %Devhub.Integrations.Schemas.GitHubApp{
      id: UXID.generate!(prefix: "gha"),
      external_id: Enum.random(1..1_000_000),
      slug: "private-devhub-tools",
      client_id: "1234",
      client_secret: "client_secret",
      webhook_secret: "webhook_secret",
      private_key: private_key,
      organization: build(:organization),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def github_user_factory do
    %Devhub.Integrations.GitHub.User{
      id: UXID.generate!(prefix: "gh_usr"),
      username: "michaelst"
    }
  end

  def commit_author_factory do
    %Devhub.Integrations.GitHub.CommitAuthor{}
  end

  def event_factory do
    %Devhub.Calendar.Event{
      id: UXID.generate!(prefix: "evt"),
      title: "OOO",
      color: "black",
      external_id: "1234",
      person: "Michael",
      start_date: DateTime.utc_now(),
      end_date: DateTime.add(DateTime.utc_now(), 4, :day)
    }
  end

  def coverage_factory do
    alphabet = Enum.to_list(?a..?f) ++ Enum.to_list(?0..?9)

    %Devhub.Coverbot.Coverage{
      id: UXID.generate!(prefix: "cov"),
      covered: 10,
      is_for_default_branch: true,
      percentage: Decimal.new("10"),
      ref: "refs/heads/main",
      relevant: 100,
      sha: 1..64 |> Enum.map(fn _sha -> Enum.random(alphabet) end) |> to_string()
    }
  end

  def test_suite_factory(attrs) do
    organization = attrs[:organization] || build(:organization)
    repository = attrs[:repository] || build(:repository, organization: organization)

    %Devhub.Coverbot.TestReports.Schemas.TestSuite{
      id: UXID.generate!(prefix: "test_suite"),
      name: attrs[:name] || "test_suite_#{Enum.random(0..9)}",
      organization: organization,
      repository: repository,
      test_suite_runs: attrs[:test_suite_runs] || [],
      inserted_at: attrs[:inserted_at] || DateTime.utc_now(),
      updated_at: attrs[:updated_at] || DateTime.utc_now()
    }
  end

  def test_suite_run_factory(attrs) do
    organization = attrs[:organization] || build(:organization)
    repository = attrs[:repository] || build(:repository, organization: organization)
    test_suite = attrs[:test_suite] || build(:test_suite, organization: organization, repository: repository)
    commit = attrs[:commit] || build(:commit, organization: organization, repository: repository)
    number_of_tests = attrs[:number_of_tests] || Enum.random(1..40)
    number_of_errors = attrs[:number_of_errors] || Enum.random(1..5)
    number_of_failures = attrs[:number_of_failures] || Enum.random(1..5)
    number_of_skipped = attrs[:number_of_skipped] || Enum.random(1..5)
    execution_time_seconds = attrs[:execution_time_seconds] || Decimal.new("15.4")
    inserted_at = attrs[:inserted_at] || DateTime.utc_now()
    updated_at = attrs[:updated_at] || DateTime.utc_now()

    %Devhub.Coverbot.TestReports.Schemas.TestSuiteRun{
      id: UXID.generate!(prefix: "test_suite_run"),
      commit: commit,
      test_suite: test_suite,
      number_of_tests: number_of_tests,
      number_of_errors: number_of_errors,
      number_of_failures: number_of_failures,
      number_of_skipped: number_of_skipped,
      execution_time_seconds: execution_time_seconds,
      inserted_at: inserted_at,
      updated_at: updated_at
    }
  end

  def test_run_factory(attrs) do
    test_suite_run = attrs[:test_suite_run] || build(:test_suite_run)
    class_name = attrs[:class_name] || "TestClass"
    file_name = attrs[:file_name] || "test_file.exs"
    test_name = attrs[:test_name] || "test_#{Enum.random(0..999)}"
    status = attrs[:status] || :passed
    execution_time_seconds = attrs[:execution_time_seconds] || Decimal.new("0.5")
    inserted_at = attrs[:inserted_at] || DateTime.utc_now()
    updated_at = attrs[:updated_at] || DateTime.utc_now()

    info =
      case status do
        :passed -> nil
        :failed -> test_run_info(attrs, :failed)
        :skipped -> test_run_info(attrs, :skipped)
      end

    %Devhub.Coverbot.TestReports.Schemas.TestRun{
      id: UXID.generate!(prefix: "test_run"),
      test_suite_run: test_suite_run,
      test_suite_run_id: test_suite_run.id,
      class_name: class_name,
      file_name: file_name,
      test_name: test_name,
      status: status,
      execution_time_seconds: execution_time_seconds,
      info: info,
      inserted_at: inserted_at,
      updated_at: updated_at
    }
  end

  defp test_run_info(attrs, :failed) do
    %Info{
      message: attrs[:info][:message] || "random message",
      stacktrace: attrs[:info][:stacktrace] || "random stacktrace"
    }
  end

  defp test_run_info(attrs, :skipped) do
    %Info{
      message: attrs[:info][:message] || "Test skipped",
      stacktrace: nil
    }
  end

  def agent_factory do
    %Devhub.Agents.Schemas.Agent{
      id: UXID.generate!(prefix: "agt"),
      name: "agent",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def workspace_factory do
    %Devhub.TerraDesk.Schemas.Workspace{
      id: UXID.generate!(prefix: "tfws"),
      name: "server-config",
      path: "terraform",
      organization: build(:organization),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def terradesk_env_var_factory do
    %Devhub.TerraDesk.Schemas.EnvVar{
      id: UXID.generate!(prefix: "tfenv"),
      name: "ENV_VAR_NAME",
      value: "ENV_VAR_VALUE"
    }
  end

  def terradesk_secret_factory do
    %Devhub.TerraDesk.Schemas.Secret{
      id: UXID.generate!(prefix: "tfsec"),
      name: "API_KEY",
      value: "api-key"
    }
  end

  def plan_factory do
    %Devhub.TerraDesk.Schemas.Plan{
      id: UXID.generate!(prefix: "tfp"),
      github_branch: "main",
      status: :queued,
      organization: build(:organization),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def database_factory do
    %Devhub.QueryDesk.Schemas.Database{
      id: UXID.generate!(prefix: "db"),
      name: "My Database",
      adapter: :postgres,
      hostname: "localhost",
      database: "devhub_test",
      restrict_access: false,
      ssl: false
    }
  end

  def user_pinned_database_factory do
    %Devhub.QueryDesk.Schemas.UserPinnedDatabase{
      id: UXID.generate!(prefix: "upd")
    }
  end

  def database_column_factory do
    %DatabaseColumn{
      type: "text",
      is_primary_key: false,
      position: 1
    }
  end

  def data_protection_policy_factory do
    %Devhub.QueryDesk.Schemas.DataProtectionPolicy{
      name: "Contractors"
    }
  end

  def data_protection_column_factory do
    %Devhub.QueryDesk.Schemas.DataProtectionColumn{
      action: :hide
    }
  end

  def data_protection_action_factory do
    %Devhub.QueryDesk.Schemas.DataProtectionAction{}
  end

  def database_credential_factory do
    %Devhub.QueryDesk.Schemas.DatabaseCredential{
      username: "postgres",
      password: "postgres",
      reviews_required: 0
    }
  end

  def query_factory do
    %Query{
      id: UXID.generate!(prefix: "qry"),
      query: "SELECT * FROM users",
      organization: build(:organization),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def saved_query_factory do
    %Devhub.QueryDesk.Schemas.SavedQuery{
      id: UXID.generate!(prefix: "sq"),
      title: "My query",
      query: "SELECT * FROM users",
      organization: build(:organization),
      private: false
    }
  end

  def shared_query_factory do
    %Devhub.QueryDesk.Schemas.SharedQuery{
      id: UXID.generate!(prefix: "sq"),
      query: "SELECT * FROM users",
      expires_at: DateTime.add(DateTime.utc_now(), 1, :day),
      restricted_access: false,
      include_results: false
    }
  end

  def comment_factory do
    %Devhub.QueryDesk.Schemas.QueryComment{
      id: UXID.generate!(prefix: "qc"),
      comment: "This is a comment",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def query_approval_factory do
    %QueryApproval{
      id: UXID.generate!(prefix: "qry_apr"),
      approved_at: DateTime.utc_now()
    }
  end

  def object_permission_factory do
    %Devhub.Users.Schemas.ObjectPermission{
      id: UXID.generate!(prefix: "perm"),
      permission: :read
    }
  end

  def uptime_service_factory do
    %Devhub.Uptime.Schemas.Service{
      id: UXID.generate!(prefix: "svc"),
      name: "Example Service",
      method: "GET",
      url: "https://example.com",
      enabled: true,
      expected_status_code: "200",
      expected_response_body: "ok",
      interval_ms: 60_000,
      timeout_ms: 10_000,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def uptime_check_factory do
    %Devhub.Uptime.Schemas.Check{
      id: UXID.generate!(prefix: "chk"),
      status: :success,
      status_code: 200,
      response_body: "ok",
      dns_time: 10,
      connect_time: 20,
      tls_time: 30,
      first_byte_time: 40,
      request_time: 100,
      time_since_last_check: 10_000,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def uptime_check_summary_factory do
    %Devhub.Uptime.Schemas.CheckSummary{
      id: UXID.generate!(prefix: "chk"),
      success_percentage: 1,
      avg_dns_time: 10,
      avg_connect_time: 20,
      avg_tls_time: 30,
      avg_first_byte_time: 40,
      avg_to_finish: 60,
      avg_request_time: 100
    }
  end

  def oidc_factory do
    %Devhub.Users.OIDC{
      discovery_document_uri: "https://accounts.google.com/.well-known/openid-configuration",
      client_id: Ecto.UUID.generate(),
      client_secret: Ecto.UUID.generate()
    }
  end

  def passkey_factory do
    %Devhub.Users.Schemas.Passkey{
      id: UXID.generate!(prefix: "pass"),
      raw_id: "2fomAYPOXkoe32isN3nAuotahwQ=",
      public_key:
        <<131, 116, 0, 0, 0, 5, 98, 255, 255, 255, 253, 109, 0, 0, 0, 32, 132, 222, 200, 238, 247, 32, 161, 225, 36, 242,
          225, 133, 132, 242, 47, 31, 121, 236, 222, 242, 215, 136, 130, 82, 184, 68, 205, 128, 48, 12, 231, 247, 98, 255,
          255, 255, 254, 109, 0, 0, 0, 32, 49, 100, 36, 179, 43, 188, 51, 86, 176, 36, 146, 165, 149, 10, 176, 51, 251,
          141, 149, 48, 115, 18, 147, 195, 10, 31, 122, 190, 162, 230, 156, 77, 98, 255, 255, 255, 255, 97, 1, 97, 1, 97,
          2, 97, 3, 98, 255, 255, 255, 249>>,
      aaguid: <<251, 252, 48, 7, 21, 78, 78, 204, 140, 11, 110, 2, 5, 87, 215, 189>>,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def ai_conversation_factory do
    %Devhub.Integrations.AI.Schemas.Conversation{
      title: "My conversation"
    }
  end

  def ai_conversation_message_factory do
    %Devhub.Integrations.AI.Schemas.ConversationMessage{
      sender: :user,
      message: "Hello"
    }
  end

  def dashboard_factory do
    %Devhub.Dashboards.Schemas.Dashboard{
      id: UXID.generate!(prefix: "dash"),
      organization: build(:organization),
      name: "My dashboard (#{Ecto.UUID.generate()})",
      restricted_access: false,
      permissions: [],
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def workflow_factory do
    %Devhub.Workflows.Schemas.Workflow{
      id: UXID.generate!(prefix: "wf"),
      organization: build(:organization),
      name: "My workflow (#{Ecto.UUID.generate()})",
      steps: [],
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def workflow_step_factory do
    %Devhub.Workflows.Schemas.Step{
      id: UXID.generate!(prefix: "wfs"),
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def workflow_run_factory do
    %Devhub.Workflows.Schemas.Run{
      id: UXID.generate!(prefix: "wfr"),
      status: :in_progress,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end

  def role_factory do
    %Devhub.Users.Schemas.Role{
      id: UXID.generate!(prefix: "role"),
      name: "admin",
      description: "admin role"
    }
  end

  def organization_user_role_factory do
    %Devhub.Users.Schemas.OrganizationUserRole{
      id: UXID.generate!(prefix: "our")
    }
  end

  def terradesk_schedule_factory do
    %Devhub.TerraDesk.Schemas.Schedule{
      id: UXID.generate!(prefix: "tfs"),
      name: "My schedule",
      cron_expression: "0 0 * * *",
      slack_channel: "#alerts",
      enabled: true
    }
  end
end
