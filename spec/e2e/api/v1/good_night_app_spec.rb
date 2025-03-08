# spec/e2e/api/v1/good_night_app_spec.rb
require 'rails_helper'

RSpec.describe "Good Night App API E2E", type: :request do
  describe "Alice's sleep tracking journey" do
    let(:alice) { create(:user, name: "Alice") }

    it "allows starting a sleep session" do
      # Start a sleep session for Alice
      post "/api/v1/sleep_records/start", params: { user_id: alice.id }

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      expect(parsed_response["status"]).to eq("success")
      expect(parsed_response["data"]["sleep_record"]).to include("id", "user_id", "start_time")
      expect(parsed_response["data"]["sleep_record"]["end_time"]).to be_nil
    end

    it "allows ending a sleep session" do # rubocop:disable RSpec/ExampleLength
      # First create a sleep record with a start time in the past
      start_time = 10.hours.ago.iso8601
      post "/api/v1/sleep_records/start", params: { user_id: alice.id, start_time: start_time }

      parsed_start_response = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      sleep_record_id = parsed_start_response["data"]["sleep_record"]["id"]

      # End the sleep session with an end time that's definitely after the start time
      end_time = 2.hours.ago.iso8601
      patch "/api/v1/sleep_records/#{sleep_record_id}/end",
            params: { user_id: alice.id, end_time: end_time }

      if response.status != 200
        # Print error details to help diagnose
        puts "Error: #{response.status}"
        puts JSON.parse(response.body) rescue response.body
      end

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(parsed_response["data"]["sleep_record"]["id"]).to eq(sleep_record_id)
      expect(parsed_response["data"]["sleep_record"]["end_time"]).not_to be_nil
    end

    it "allows viewing personal sleep records" do
      # First create and end a sleep record
      post "/api/v1/sleep_records/start", params: { user_id: alice.id }
      sleep_record_id = JSON.parse(response.body)["data"]["sleep_record"]["id"]
      patch "/api/v1/sleep_records/#{sleep_record_id}/end", params: { user_id: alice.id }

      # View sleep records
      get "/api/v1/sleep_records", params: { user_id: alice.id }

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(parsed_response["data"]["sleep_records"]).to be_an(Array)

      # Find the record created
      record = parsed_response["data"]["sleep_records"].find { |r| r["id"] == sleep_record_id }
      expect(record).to be_present
    end
  end

  describe "Alice's following journey" do
    let(:alice) { create(:user, name: "Alice") }
    let(:bob) { create(:user, name: "Bob") }
    let(:charlie) { create(:user, name: "Charlie") }

    it "allows following other users" do
      # Alice follows Bob
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: bob.id }

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      expect(parsed_response["data"]["following"]["follower_id"]).to eq(alice.id)
      expect(parsed_response["data"]["following"]["followed_id"]).to eq(bob.id)
    end

    it "allows viewing followed users" do
      # Setup: Alice follows both Bob and Charlie
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: bob.id }
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: charlie.id }

      # View followed users
      get "/api/v1/followings", params: { user_id: alice.id }

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(parsed_response["data"]).to have_key("followed_users")

      followed_user_ids = parsed_response["data"]["followed_users"].map { |u| u["id"] }
      expect(followed_user_ids).to include(bob.id, charlie.id)
    end

    it "allows viewing sleep records of followed users" do
      # Setup: Alice follows both Bob and Charlie
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: bob.id }
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: charlie.id }

      # Create sleep records for Bob and Charlie
      create(:sleep_record, user: bob, start_time: 1.day.ago, end_time: 16.hours.ago)
      create(:sleep_record, user: charlie, start_time: 2.hours.ago, end_time: nil)

      # View all followed sleep records
      get "/api/v1/followings/sleep_records", params: { user_id: alice.id }

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)

      sleep_record_user_ids = parsed_response["data"]["sleep_records"].map { |r| r["user_id"] }
      expect(sleep_record_user_ids).to include(bob.id, charlie.id)
    end

    it "allows filtering followed users' sleep records" do
      # Setup: Alice follows both Bob and Charlie
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: bob.id }
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: charlie.id }

      # Create sleep records
      create(:sleep_record, user: bob, start_time: 1.day.ago, end_time: 16.hours.ago)
      create(:sleep_record, user: charlie, start_time: 2.hours.ago, end_time: nil)

      # Filter to only completed records
      get "/api/v1/followings/sleep_records", params: {
        user_id: alice.id,
        completed_only: true
      }

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)

      user_ids = parsed_response["data"]["sleep_records"].map { |r| r["user_id"] }
      expect(user_ids).to include(bob.id)
      expect(user_ids).not_to include(charlie.id)
    end

    it "allows filtering by specific followed users" do
      # Setup: Alice follows both Bob and Charlie
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: bob.id }
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: charlie.id }

      # Create sleep records
      create(:sleep_record, user: bob, start_time: 1.day.ago, end_time: 16.hours.ago)
      create(:sleep_record, user: charlie, start_time: 2.hours.ago, end_time: nil)

      # Filter to only Bob's records
      get "/api/v1/followings/sleep_records", params: {
        user_id: alice.id,
        followed_user_ids: [ bob.id ]
      }

      parsed_response = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)

      user_ids = parsed_response["data"]["sleep_records"].map { |r| r["user_id"] }.uniq
      expect(user_ids).to contain_exactly(bob.id)
    end

    it "allows unfollowing a user" do
      # Setup: Alice follows both Bob and Charlie
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: bob.id }
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: charlie.id }

      # Unfollow Charlie
      delete "/api/v1/followings", params: {
        follower_id: alice.id,
        followed_id: charlie.id
      }

      expect(response).to have_http_status(:no_content)

      # Verify Alice no longer follows Charlie
      get "/api/v1/followings", params: { user_id: alice.id }

      parsed_response = JSON.parse(response.body)
      followed_user_ids = parsed_response["data"]["followed_users"].map { |u| u["id"] }
      expect(followed_user_ids).to include(bob.id)
      expect(followed_user_ids).not_to include(charlie.id)
    end

    it "removes unfollowed users' records from the feed" do
      # Setup: Alice follows both Bob and Charlie
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: bob.id }
      post "/api/v1/followings", params: { follower_id: alice.id, followed_id: charlie.id }

      # Create sleep records
      create(:sleep_record, user: bob, start_time: 1.day.ago, end_time: 16.hours.ago)
      create(:sleep_record, user: charlie, start_time: 2.hours.ago, end_time: nil)

      # Unfollow Charlie
      delete "/api/v1/followings", params: {
        follower_id: alice.id,
        followed_id: charlie.id
      }

      # Check the feed
      get "/api/v1/followings/sleep_records", params: { user_id: alice.id }

      parsed_response = JSON.parse(response.body)
      user_ids = parsed_response["data"]["sleep_records"].map { |r| r["user_id"] }.uniq
      expect(user_ids).to include(bob.id)
      expect(user_ids).not_to include(charlie.id)
    end
  end
end
