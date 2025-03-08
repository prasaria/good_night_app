# spec/e2e/api/v1/edge_cases_spec.rb
require 'rails_helper'

RSpec.describe "Good Night App API Edge Cases", type: :request do
  let!(:user) { create(:user, name: "Test User") }
  let(:json_response) { JSON.parse(response.body) }

  describe "Handling concurrent sleep records" do
    it "prevents a user from starting multiple sleep sessions" do
      # Start the first sleep session
      post "/api/v1/sleep_records/start", params: { user_id: user.id }
      expect(response).to have_http_status(:created)

      # Try to start another session - should fail
      post "/api/v1/sleep_records/start", params: { user_id: user.id }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["status"]).to eq("error")
      expect(json_response["details"]).to include("already have an in-progress sleep record")
    end

    it "allows starting a new session after ending the previous one" do
      # Start a sleep session
      post "/api/v1/sleep_records/start", params: { user_id: user.id }
      expect(response).to have_http_status(:created)
      sleep_record_id = json_response["data"]["sleep_record"]["id"]

      # End the session
      patch "/api/v1/sleep_records/#{sleep_record_id}/end", params: { user_id: user.id }
      expect(response).to have_http_status(:ok)

      # Should now be able to start a new session
      post "/api/v1/sleep_records/start", params: { user_id: user.id }
      expect(response).to have_http_status(:created)
    end
  end

  describe "Date restrictions" do
    it "prevents using future dates" do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # Make sure no existing sleep records for this test
      user.sleep_records.destroy_all

      # 1. Try to start with future time
      future_time = 1.hour.from_now.iso8601
      post "/api/v1/sleep_records/start", params: { user_id: user.id, start_time: future_time }

      # Verify it's rejected
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["status"]).to eq("error")  # It returns "error", not "success"
      expect(json_response["details"]).to include("cannot be in the future")

      # 2. Create a valid sleep record
      past_time = 5.hours.ago.iso8601
      post "/api/v1/sleep_records/start", params: { user_id: user.id, start_time: past_time }

      # Verify it's created
      expect(response).to have_http_status(:created)
      sleep_record = JSON.parse(response.body)
      sleep_record_id = sleep_record["data"]["sleep_record"]["id"]

      # 3. Try to end with future time
      future_time = 1.hour.from_now.iso8601
      patch "/api/v1/sleep_records/#{sleep_record_id}/end", params: { user_id: user.id, end_time: future_time }

      # Verify it's rejected
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["status"]).to eq("error")
      expect(json_response["details"]).to include("cannot be in the future")
    end

    it "prevents end time being before start time" do
      # Clear any existing sleep records
      user.sleep_records.destroy_all

      # 1. Create a valid sleep record with explicit start time
      start_time = 5.hours.ago.iso8601
      post "/api/v1/sleep_records/start", params: { user_id: user.id, start_time: start_time }

      # Verify it's created
      expect(response).to have_http_status(:created)
      sleep_record = JSON.parse(response.body)
      sleep_record_id = sleep_record["data"]["sleep_record"]["id"]

      # 2. Try to end it with time before start time
      end_time = 6.hours.ago.iso8601
      patch "/api/v1/sleep_records/#{sleep_record_id}/end", params: { user_id: user.id, end_time: end_time }

      # Verify it's rejected with the specific error message we saw in logs
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["status"]).to eq("error")
      expect(json_response["details"]).to eq("End time must be after start time")
    end
  end

  describe "Following restrictions" do
    let!(:other_user) { create(:user, name: "Other User") }

    it "prevents self-following" do
      post "/api/v1/followings", params: { follower_id: user.id, followed_id: user.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["details"]).to include("cannot follow yourself")
    end

    it "prevents duplicate followings" do
      # First follow should succeed
      post "/api/v1/followings", params: { follower_id: user.id, followed_id: other_user.id }
      expect(response).to have_http_status(:created)

      # Second follow should fail
      post "/api/v1/followings", params: { follower_id: user.id, followed_id: other_user.id }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["details"]).to include("already following")
    end
  end

  describe "Pagination and sorting" do
    before do
      # Create multiple sleep records for the test user
      create_list(:sleep_record, 15, user: user, end_time: 1.hour.ago, duration_minutes: 8 * 60)
    end

    describe "pagination" do
      it "returns the first page correctly" do
        get "/api/v1/sleep_records", params: { user_id: user.id, page: 1, per_page: 5 }

        expect(response).to have_http_status(:ok)
        expect(json_response["data"]["sleep_records"].length).to eq(5)
        expect(json_response["data"]["pagination"]["current_page"]).to eq(1)
        expect(json_response["data"]["pagination"]["total_pages"]).to eq(3)
      end

      it "returns the second page correctly" do
        get "/api/v1/sleep_records", params: { user_id: user.id, page: 2, per_page: 5 }

        expect(response).to have_http_status(:ok)
        expect(json_response["data"]["sleep_records"].length).to eq(5)
        expect(json_response["data"]["pagination"]["current_page"]).to eq(2)
      end
    end

    describe "sorting" do
      before do
        # Clear any existing sleep records for this user
        user.sleep_records.destroy_all

        # Create records with different durations that don't overlap
        create(:sleep_record, user: user, start_time: 20.hours.ago, end_time: 12.hours.ago, duration_minutes: 8 * 60)
        create(:sleep_record, user: user, start_time: 10.hours.ago, end_time: 6.hours.ago, duration_minutes: 4 * 60)
        create(:sleep_record, user: user, start_time: 5.hours.ago, end_time: 2.hours.ago, duration_minutes: 3 * 60)
      end

      it "sorts by duration in ascending order" do
        get "/api/v1/sleep_records", params: {
          user_id: user.id,
          sort_by: "duration",
          sort_direction: "asc"
        }

        expect(response).to have_http_status(:ok)
        durations = json_response["data"]["sleep_records"].map { |r| r["duration_minutes"] }
        expect(durations).to eq(durations.sort)
      end

      it "sorts by start_time in descending order" do
        get "/api/v1/sleep_records", params: {
          user_id: user.id,
          sort_by: "start_time",
          sort_direction: "desc"
        }

        expect(response).to have_http_status(:ok)
        start_times = json_response["data"]["sleep_records"].map { |r| Time.zone.parse(r["start_time"]) }
        expect(start_times).to eq(start_times.sort.reverse)
      end
    end
  end
end
