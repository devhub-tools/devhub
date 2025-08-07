defmodule DevhubWeb.PostgresProxyTest do
  use Devhub.DataCase, async: false

  test "connect and send query" do
    organization = insert(:organization)
    user = insert(:user)
    {:ok, proxy_password} = Devhub.Users.generate_proxy_password(user, 3600)
    organization_user = insert(:organization_user, organization: organization, user: user)

    database =
      insert(:database,
        credentials: [build(:database_credential, default_credential: true)],
        organization: organization_user.organization,
        permissions: [build(:object_permission, permission: :write, organization_user: organization_user)]
      )

    {:ok, socket} = :gen_tcp.connect(~c"localhost", 54_321, mode: :binary, active: false, packet: :raw)

    :gen_tcp.send(
      socket,
      <<8::integer-size(32), 1234::integer-size(16), 5679::integer-size(16)>>
    )

    assert {:ok, <<?S>>} = :gen_tcp.recv(socket, 1)

    {:ok, socket} = :ssl.connect(socket, verify: :verify_none)

    startup_msg =
      <<0, 3, 0, 0, "user", 0, user.email::binary, 0, "database", 0, database.name::binary, 0, 111, 112, 116, 105, 111,
        110, 115, 0, 45, 99, 32, 101, 120, 116, 114, 97, 95, 102, 108, 111, 97, 116, 95, 100, 105, 103, 105, 116, 115, 61,
        51, 0, 97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 95, 110, 97, 109, 101, 0, 80, 111, 115, 116, 105, 99,
        111, 32, 49, 46, 53, 46, 50, 49, 0, 99, 108, 105, 101, 110, 116, 95, 101, 110, 99, 111, 100, 105, 110, 103, 0, 85,
        78, 73, 67, 79, 68, 69, 0, 0>>

    size = byte_size(startup_msg) + 4

    assert :ok = :ssl.send(socket, <<size::integer-size(32), startup_msg::binary>>)

    # password required message
    assert {:ok, <<?R, 0, 0, 0, 23, 0, 0, 0, 10, "SCRAM-SHA-256", 0, 0>>} = :ssl.recv(socket, 0)

    # SASL client first
    msg = :binary.list_to_bin(Postgrex.SCRAM.client_first())
    size = byte_size(msg) + 4

    assert :ok = :ssl.send(socket, <<?p, size::integer-size(32), msg::binary>>)

    # SASL cont from server
    assert {:ok, <<?R, _length::integer-size(32), 0, 0, 0, 11, sasl_cont::binary>>} = :ssl.recv(socket, 0)

    # SASL cont response
    {client_final_msg, scram_state} = Postgrex.SCRAM.client_final(sasl_cont, password: proxy_password)
    msg = :binary.list_to_bin(client_final_msg)
    size = byte_size(msg) + 4

    assert :ok = :ssl.send(socket, <<?p, size::integer-size(32), msg::binary>>)

    # auth successful
    {:ok, <<?R, _length::integer-size(32), 0, 0, 0, 12, sasl_final::binary>>} = :ssl.recv(socket, 0)
    assert :ok = Postgrex.SCRAM.verify_server(sasl_final, scram_state, password: proxy_password)

    {:ok, <<?R, 0, 0, 0, 8, 0, 0, 0, 0, _rest::binary>>} = :ssl.recv(socket, 0)

    query = "SELECT datName FROM pg_database WHERE datAllowConn ORDER BY datName"
    size = byte_size(query) + 4
    query_msg = <<?Q, size::integer-size(32), query::binary>>

    assert :ok = :ssl.send(socket, query_msg)

    {:ok,
     <<?T, _desc_size::integer-32, _field_count::integer-16, field::binary-7, 0, 0::integer-32, 0::integer-16,
       25::integer-32, -1::signed-integer-16, -1::signed-integer-32, 0::integer-16, ?D, _data_size::integer-32,
       _row_count::integer-16, _value_size::integer-32, value::binary-11, ?C, _cmd_size::integer-size(32), "SELECT 1", 0,
       ?Z, 0, 0, 0, 5, ?I>>} = :ssl.recv(socket, 0)

    assert field == "datName"
    assert value == "My Database"

    query = "SELECT * FROM users"
    size = byte_size(query) + 4

    # send messages separately to test continuation
    :ok = :ssl.send(socket, <<?Q, size::integer-size(32)>>)
    :timer.sleep(10)
    :ok = :ssl.send(socket, <<query::binary>>)

    {:ok, <<?T, _rest::binary>>} = :ssl.recv(socket, 0)

    # terminate connection
    :ok = :ssl.send(socket, <<?X>>)
  end

  test "invalid password" do
    organization = insert(:organization)
    user = insert(:user)
    {:ok, _proxy_password} = Devhub.Users.generate_proxy_password(user, 3600)
    organization_user = insert(:organization_user, organization: organization, user: user)

    database =
      insert(:database, default_credential: build(:database_credential), organization: organization_user.organization)

    {:ok, socket} = :gen_tcp.connect(~c"localhost", 54_321, mode: :binary, active: false, packet: :raw)

    :gen_tcp.send(
      socket,
      <<8::integer-size(32), 1234::integer-size(16), 5679::integer-size(16)>>
    )

    assert {:ok, <<?S>>} = :gen_tcp.recv(socket, 1)

    {:ok, socket} = :ssl.connect(socket, verify: :verify_none)

    startup_msg =
      <<0, 3, 0, 0, "user", 0, user.email::binary, 0, "database", 0, database.name::binary, 0, 111, 112, 116, 105, 111,
        110, 115, 0, 45, 99, 32, 101, 120, 116, 114, 97, 95, 102, 108, 111, 97, 116, 95, 100, 105, 103, 105, 116, 115, 61,
        51, 0, 97, 112, 112, 108, 105, 99, 97, 116, 105, 111, 110, 95, 110, 97, 109, 101, 0, 80, 111, 115, 116, 105, 99,
        111, 32, 49, 46, 53, 46, 50, 49, 0, 99, 108, 105, 101, 110, 116, 95, 101, 110, 99, 111, 100, 105, 110, 103, 0, 85,
        78, 73, 67, 79, 68, 69, 0, 0>>

    size = byte_size(startup_msg) + 4

    assert :ok = :ssl.send(socket, <<size::integer-size(32), startup_msg::binary>>)

    # password required message
    assert {:ok, <<?R, 0, 0, 0, 23, 0, 0, 0, 10, "SCRAM-SHA-256", 0, 0>>} = :ssl.recv(socket, 0)

    # SASL client first
    msg = :binary.list_to_bin(Postgrex.SCRAM.client_first())
    size = byte_size(msg) + 4

    assert :ok = :ssl.send(socket, <<?p, size::integer-size(32), msg::binary>>)

    # SASL cont from server
    assert {:ok, <<?R, _length::integer-size(32), 0, 0, 0, 11, sasl_cont::binary>>} = :ssl.recv(socket, 0)

    # SASL cont response
    {client_final_msg, _scram_state} = Postgrex.SCRAM.client_final(sasl_cont, password: "wrong")
    msg = :binary.list_to_bin(client_final_msg)
    size = byte_size(msg) + 4

    assert :ok = :ssl.send(socket, <<?p, size::integer-size(32), msg::binary>>)

    {:ok,
     <<?E, 0, 0, 0, 57, ?S, "FATAL", 0, ?V, "FATAL", 0, ?C, "28P01", 0, ?M, "invalid password", 0, ?R, "auth_failed", 0,
       0>>} =
      :ssl.recv(socket, 0)
  end
end
