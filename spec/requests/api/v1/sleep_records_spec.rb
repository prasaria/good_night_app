# spec/requests/api/v1/sleep_records_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::SleepRecords", type: :request do
  describe "POST /api/v1/sleep_records/start" do
    let(:user) { create(:user) }
    let(:valid_params) { { user_id: user.id } }

    context "with valid parameters" do
      it "creates a new sleep record with start time" do
        expect {
          post "/api/v1/sleep_records/start", params: valid_params
        }.to change(SleepRecord, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
      end

      it "returns the created sleep record" do
        post "/api/v1/sleep_records/start", params: valid_params

        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("success")
        expect(json_response["data"]["sleep_record"]).to include("id", "user_id", "start_time")
        expect(json_response["data"]["sleep_record"]["user_id"]).to eq(user.id)
        expect(json_response["data"]["sleep_record"]["end_time"]).to be_nil
      end

      it "creates a sleep record with the current time" do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        post "/api/v1/sleep_records/start", params: valid_params

        json_response = JSON.parse(response.body)
        record_time = Time.zone.parse(json_response["data"]["sleep_record"]["start_time"])
        expect(record_time).to be_within(1.second).of(freeze_time)
      end

      it "allows specifying a custom start time" do
        custom_time = 1.hour.ago
        post "/api/v1/sleep_records/start", params: valid_params.merge(start_time: custom_time.iso8601)

        json_response = JSON.parse(response.body)
        record_time = Time.zone.parse(json_response["data"]["sleep_record"]["start_time"])
        expect(record_time).to be_within(1.second).of(custom_time)
      end
    end

    context "with invalid parameters" do
      it "returns error when user_id is missing" do
        post "/api/v1/sleep_records/start", params: {}

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Bad request")
      end

      it "returns error when user doesn't exist" do
        post "/api/v1/sleep_records/start", params: { user_id: 999999 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Not found")
      end

      it "returns error when user already has an in-progress sleep record" do
        # Create an in-progress sleep record
        create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil)

        post "/api/v1/sleep_records/start", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("already have an in-progress sleep record")
      end

      it "returns error when start time is in the future" do
        future_time = 1.hour.from_now
        post "/api/v1/sleep_records/start", params: valid_params.merge(start_time: future_time.iso8601)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("cannot be in the future")
      end
    end
  end
end
