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
        expect(json_response["message"]).to eq("user_id parameter is required")
      end

      it "returns error when user doesn't exist" do
        post "/api/v1/sleep_records/start", params: { user_id: 999999 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("User not found")
      end

      it "returns error when user already has an in-progress sleep record" do
        # Create an in-progress sleep record
        create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil)

        post "/api/v1/sleep_records/start", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to include("already have an in-progress sleep record")
        expect(json_response["details"]).to eq([ "You already have an in-progress sleep record" ])
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

  describe "PATCH /api/v1/sleep_records/:id/end" do
    let(:user) { create(:user) }
    let(:sleep_record) { create(:sleep_record, user: user, start_time: 8.hours.ago, end_time: nil) }
    let(:valid_params) { { user_id: user.id } }

    context "with valid parameters" do
      it "updates the sleep record with current end time" do
        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: valid_params

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")

        # Check that record was updated
        sleep_record.reload
        expect(sleep_record.end_time).to be_present
        expect(sleep_record.duration_minutes).to be_present
      end

      it "returns the updated sleep record" do
        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: valid_params

        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("success")
        expect(json_response["data"]["sleep_record"]).to include("id", "user_id", "start_time", "end_time", "duration_minutes")
        expect(json_response["data"]["sleep_record"]["id"]).to eq(sleep_record.id)
      end

      it "calculates the correct duration" do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: valid_params

        json_response = JSON.parse(response.body)
        expected_duration = ((freeze_time - sleep_record.start_time) / 60).to_i
        expect(json_response["data"]["sleep_record"]["duration_minutes"]).to be_within(1).of(expected_duration)
      end

      it "allows specifying a custom end time" do
        custom_time = 1.hour.ago
        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: valid_params.merge(end_time: custom_time.iso8601)

        json_response = JSON.parse(response.body)
        record_time = Time.zone.parse(json_response["data"]["sleep_record"]["end_time"])
        expect(record_time).to be_within(1.second).of(custom_time)
      end
    end

    context "with invalid parameters" do
      it "returns error when sleep record doesn't exist" do
        patch "/api/v1/sleep_records/999999/end", params: valid_params

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
      end

      it "returns error when user_id is missing" do
        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: {}

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
      end

      it "returns error when user doesn't match the sleep record" do
        other_user = create(:user)
        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: { user_id: other_user.id }

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("not authorized")
      end

      it "returns error when sleep record is already completed" do
        # Create a completed sleep record
        completed_record = create(:sleep_record, user: user, start_time: 10.hours.ago, end_time: 2.hours.ago)

        patch "/api/v1/sleep_records/#{completed_record.id}/end", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("already completed")
      end

      it "returns error when end time is before start time" do
        invalid_end_time = sleep_record.start_time - 1.hour
        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: valid_params.merge(end_time: invalid_end_time.iso8601)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("must be after start time")
      end

      it "returns error when end time is in the future" do
        future_time = 1.hour.from_now
        patch "/api/v1/sleep_records/#{sleep_record.id}/end", params: valid_params.merge(end_time: future_time.iso8601)

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("cannot be in the future")
      end
    end
  end
end
