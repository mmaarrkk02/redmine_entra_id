# frozen_string_literal: true

require_relative "../test_helper"

class GroupsControllerTest < Redmine::IntegrationTest
  setup do
    @admin = users(:users_001)
    @entra_group = Group.create!(
      lastname: "🆔 Entra Group",
      oid: "entra-group-oid-12345",
      synced_at: Time.zone.parse("2025-01-15 10:30:00")
    )
    @normal_group = Group.generate!
    log_user(@admin.login, "admin")
  end

  test "should display entra sync info for synced groups in edit form" do
    get edit_group_path(@entra_group)
    assert_response :success

    expected_time = ApplicationController.helpers.format_time(@entra_group.synced_at)
    assert_select "p", text: /#{Regexp.escape(I18n.t(:field_entra_id_oid))}.*#{Regexp.escape(@entra_group.oid)}/
    assert_select "p", text: /#{Regexp.escape(I18n.t(:label_last_entra_id_sync))}.*#{Regexp.escape(expected_time)}/
  end

  test "should not display entra sync info for groups without entra data" do
    get edit_group_path(@normal_group)
    assert_response :success

    assert_select "p", text: /#{Regexp.escape(I18n.t(:field_entra_id_oid))}/, count: 0
    assert_select "p", text: /#{Regexp.escape(I18n.t(:label_last_entra_id_sync))}/, count: 0
  end
end
