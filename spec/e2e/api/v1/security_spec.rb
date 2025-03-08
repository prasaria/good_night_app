# spec/e2e/api/v1/security_spec.rb
require 'rails_helper'

RSpec.describe "Good Night App API Security", type: :request do
  let(:user_a) { create(:user, name: "User A") }
  let(:user_b) { create(:user, name: "User B") }

  # Helper method to parse response body
  def json_response
    JSON.parse(response.body) rescue nil
  end

  describe "Sleep record ownership" do
    it "prevents ending another user's sleep record" do
      # User A starts a sleep session
      post "/api/v1/sleep_records/start", params: { user_id: user_a.id }
      expect(response).to have_http_status(:created)

      # Extract sleep record ID
      start_response = JSON.parse(response.body)
      sleep_record_id = start_response["data"]["sleep_record"]["id"]

      # User B tries to end User A's sleep record
      patch "/api/v1/sleep_records/#{sleep_record_id}/end", params: { user_id: user_b.id }

      expect(response).to have_http_status(:forbidden)
      expect(json_response["status"]).to eq("error")
      expect(json_response["details"]).to include("not authorized")
    end
  end

  describe "API error handling" do
    it "returns not found for non-existent resources" do
      # Try to get a non-existent user's sleep records
      get "/api/v1/sleep_records", params: { user_id: 999999 }

      expect(response).to have_http_status(:not_found)
      expect(json_response["status"]).to eq("error")

      # Try to end a non-existent sleep record
      patch "/api/v1/sleep_records/999999/end", params: { user_id: user_a.id }

      expect(response).to have_http_status(:not_found)
      expect(json_response["status"]).to eq("error")
    end

    it "handles bad requests gracefully" do
      # Test a malformed date
      post "/api/v1/sleep_records/start", params: {
        user_id: user_a.id,
        start_time: "not-a-date"
      }

      expect(response).to have_http_status(:bad_request)
      expect(json_response["status"]).to eq("error")

      # Test invalid filtering parameters
      get "/api/v1/sleep_records", params: {
        user_id: user_a.id,
        start_date: "invalid-date"
      }

      expect(response).to have_http_status(:bad_request)
      expect(json_response["status"]).to eq("error")
    end
  end
end
