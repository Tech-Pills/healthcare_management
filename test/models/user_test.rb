require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "staff? returns true when user has staff" do
    user = users(:one)
    assert user.staff?
  end

  test "staff? returns false when user has no staff" do
    user = User.new(email_address: "test@example.com", password: "password")

    assert_not user.staff?
  end

  test "delegates full_name to staff" do
    user = users(:one)
    assert_equal "John Admin", user.full_name
  end

  test "delegates role to staff" do
    user = users(:one)
    assert_equal "admin", user.role
  end

  test "delegates return nil when staff is nil" do
    user = User.new(email_address: "test@example.com", password: "password")

    assert_nil user.full_name
    assert_nil user.role
    assert_nil user.active?
    assert_nil user.practice
  end

  test "has_one staff association" do
    user = users(:one)

    assert_respond_to user, :staff
    assert_instance_of Staff, user.staff
  end

  test "staff association returns correct record" do
    user = users(:one)
    staff = user.staff

    assert_equal staffs(:admin).id, staff.id
    assert_equal user.id, staff.user_id
    assert_equal "John", staff.first_name
    assert_equal "Admin", staff.last_name
  end

  test "practice association returns correct record through staff" do
    user = users(:one)
    practice = user.practice

    assert_not_nil practice
    assert_instance_of Practice, practice
    assert_equal practices(:one).id, practice.id
    assert_equal "Test Medical Center", practice.name

    assert_equal user.staff.practice_id, practice.id
  end

  test "staff association queries tenant database" do
    user = users(:one)

    assert_equal "primary_test-medical-center", User.connection_db_config.name
    assert_includes User.connection_db_config.database, "test/test-medical-center"

    assert_equal "primary_test-medical-center", Staff.connection_db_config.name
    assert_includes Staff.connection_db_config.database, "test/test-medical-center"

    staff = user.staff
    assert_not_nil staff
    assert_equal user.id, staff.user_id
  end

  test "practice association works across databases with disable_joins" do
    user = users(:one)

    assert_equal "primary_test-medical-center", User.connection_db_config.name

    assert_equal "global", Practice.connection_db_config.name
    assert_includes Practice.connection_db_config.database, "test_global"

    practice = user.practice
    assert_not_nil practice
    assert_instance_of Practice, practice
    assert_equal practices(:one).id, practice.id
  end

  test "can eager load staff association" do
    users = User.includes(:staff).where(id: users(:one).id)
    user = users.first

    assert_no_queries do
      assert_equal "John Admin", user.staff.full_name
    end
  end

  test "practice association returns nil for user without staff" do
    user = User.create!(email_address: "nostaff@example.com", password: "password")

    assert_nil user.staff
    assert_nil user.practice
  end

  test "practice association uses disable_joins to avoid cross-database JOIN" do
    user = users(:one)

    queries = []
    counter = ->(*, payload) do
      unless payload[:name] == "SCHEMA"
        queries << payload[:sql]
      end
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      user.practice
    end

    staff_queries = queries.select { |q| q.include?("staffs") }
    practice_queries = queries.select { |q| q.include?("practices") }

    assert_equal 1, staff_queries.count, "Should query staffs table once"
    assert_equal 1, practice_queries.count, "Should query practices table once"

    queries.each do |sql|
      assert_not sql.upcase.include?("JOIN"), "Should not use JOIN: #{sql}"
    end
  end
end
