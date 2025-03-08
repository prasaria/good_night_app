# spec/requests/api/v1/followings_sleep_records_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::FollowingsSleepRecords", type: :request do
  describe "GET /api/v1/followings/sleep_records" do
    let(:user) { create(:user) }
    let(:valid_params) { { user_id: user.id } }

    # Use let! to create followed users before each test
    let!(:followed_users) do
      users = create_list(:user, 3)

      # Create followings
      users.each do |followed_user|
        create(:following, follower: user, followed: followed_user)
      end

      # Create sleep records for first followed user
      create(:sleep_record, user: users[0], start_time: 1.day.ago, end_time: 16.hours.ago, duration_minutes: 8 * 60)
      create(:sleep_record, user: users[0], start_time: 3.days.ago, end_time: 64.hours.ago, duration_minutes: 8 * 60)

      # Create sleep records for second followed user
      create(:sleep_record, user: users[1], start_time: 2.days.ago, end_time: 40.hours.ago, duration_minutes: 8 * 60)
      create(:sleep_record, user: users[1], start_time: 8.days.ago, end_time: 7.days.ago, duration_minutes: 24 * 60)

      # Create in-progress sleep record for third followed user
      create(:sleep_record, user: users[2], start_time: 2.hours.ago, end_time: nil)

      # Create a sleep record for a non-followed user
      non_followed_user = create(:user)
      create(:sleep_record, user: non_followed_user, start_time: 1.day.ago, end_time: 16.hours.ago)

      users # Return the created users
    end

    context "with valid parameters" do
      it "returns sleep records from followed users" do
        get "/api/v1/followings/sleep_records", params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["status"]).to eq("success")
        expect(json_response["data"]["sleep_records"].length).to eq(5) # All records from followed users

        # Verify sleep record structure
        expect(json_response["data"]["sleep_records"].first).to include(
          "id", "user_id", "start_time", "end_time", "duration_minutes"
        )
      end

      it "includes user information with each sleep record" do
        get "/api/v1/followings/sleep_records", params: valid_params

        json_response = JSON.parse(response.body)
        first_record = json_response["data"]["sleep_records"].first

        expect(first_record).to have_key("user")
        expect(first_record["user"]).to include("id", "name")
        expect(followed_users.map(&:id)).to include(first_record["user"]["id"])
      end

      it "includes pagination metadata" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(page: 1, per_page: 2)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["pagination"]).to include(
          "current_page", "total_pages", "total_count", "per_page"
        )
        expect(json_response["data"]["pagination"]["current_page"]).to eq(1)
        expect(json_response["data"]["pagination"]["total_count"]).to eq(5)
      end
    end

    context "when filtering by status" do
      it "returns only completed sleep records" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(completed_only: true)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["sleep_records"].length).to eq(4) # 4 completed records

        # All returned records should have an end_time
        expect(json_response["data"]["sleep_records"].map { |r| r["end_time"] }).to all(be_present)
      end

      it "returns only in-progress sleep records" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(in_progress_only: true)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["sleep_records"].length).to eq(1) # 1 in-progress record

        # The returned record should have a nil end_time
        expect(json_response["data"]["sleep_records"].first["end_time"]).to be_nil
      end
    end

    context "when filtering by date range" do
      it "returns sleep records from last week" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(from_last_week: true)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["sleep_records"].length).to eq(4) # 4 records within the last week
      end

      it "returns sleep records from custom start date" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(start_date: 2.days.ago.iso8601)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["sleep_records"].length).to eq(3) # 3 records from last 2 days
      end

      it "returns sleep records until custom end date" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(end_date: 4.days.ago.iso8601)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["sleep_records"].length).to eq(1) # 1 record before 4 days ago
      end
    end

    context "when filtering by specific followed users" do
      it "returns records from the specified followed users" do
        # Pass the IDs as an array parameter
        params = valid_params.merge(
          followed_user_ids: [ followed_users[0].id.to_s, followed_users[1].id.to_s ]
        )

        get "/api/v1/followings/sleep_records", params: params

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["sleep_records"].length).to eq(4) # 4 records from first two followed users

        user_ids = json_response["data"]["sleep_records"].map { |r| r["user_id"] }.uniq
        expect(user_ids).to contain_exactly(followed_users[0].id, followed_users[1].id)
      end

      it "ignores user IDs that are not being followed" do
        non_followed_user = create(:user)

        # Pass the IDs as an array parameter
        params = valid_params.merge(
          followed_user_ids: [ followed_users[0].id.to_s, non_followed_user.id.to_s ]
        )

        get "/api/v1/followings/sleep_records", params: params

        json_response = JSON.parse(response.body)
        user_ids = json_response["data"]["sleep_records"].map { |r| r["user_id"] }.uniq
        expect(user_ids).to contain_exactly(followed_users[0].id)
        expect(user_ids).not_to include(non_followed_user.id)
      end
    end

    context "with sorting parameters" do
      it "sorts by duration in descending order" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(
          sort_by: "duration",
          sort_direction: "desc",
          completed_only: true
        )

        json_response = JSON.parse(response.body)
        durations = json_response["data"]["sleep_records"].map { |r| r["duration_minutes"] }
        expect(durations).to eq(durations.sort.reverse)
      end

      it "sorts by start_time" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(
          sort_by: "start_time",
          sort_direction: "asc"
        )

        json_response = JSON.parse(response.body)
        start_times = json_response["data"]["sleep_records"].map { |r| Time.zone.parse(r["start_time"]) }
        expect(start_times).to eq(start_times.sort)
      end
    end

    context "when user follows no one" do
      it "returns an empty array" do
        user_with_no_followings = create(:user)

        get "/api/v1/followings/sleep_records", params: { user_id: user_with_no_followings.id }

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["sleep_records"]).to be_empty

        # Check that pagination exists and has the correct values
        expect(json_response["data"]["pagination"]).to be_present
        expect(json_response["data"]["pagination"]["total_count"]).to eq(0)
      end
    end

    context "with invalid parameters" do
      it "returns error when user_id is missing" do
        get "/api/v1/followings/sleep_records"

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("user_id parameter is required")
      end

      it "returns error when user doesn't exist" do
        get "/api/v1/followings/sleep_records", params: { user_id: 999999 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("User not found")
      end

      it "returns error when date format is invalid" do
        get "/api/v1/followings/sleep_records", params: valid_params.merge(start_date: "invalid-date")

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("Invalid start_date format")
      end
    end
  end
end
