# spec/requests/api/v1/followings_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Followings", type: :request do
  describe "POST /api/v1/followings" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }
    let(:valid_params) { { follower_id: follower.id, followed_id: followed.id } }

    context "with valid parameters" do
      it "creates a new following relationship" do
        expect {
          post "/api/v1/followings", params: valid_params
        }.to change(Following, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
      end

      it "returns the created following relationship" do
        post "/api/v1/followings", params: valid_params

        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("success")
        expect(json_response["data"]["following"]).to include("id", "follower_id", "followed_id")
        expect(json_response["data"]["following"]["follower_id"]).to eq(follower.id)
        expect(json_response["data"]["following"]["followed_id"]).to eq(followed.id)
      end

      it "includes follower and followed user information" do
        post "/api/v1/followings", params: valid_params

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["following"]["follower"]).to include("id", "name")
        expect(json_response["data"]["following"]["followed"]).to include("id", "name")
        expect(json_response["data"]["following"]["follower"]["id"]).to eq(follower.id)
        expect(json_response["data"]["following"]["followed"]["id"]).to eq(followed.id)
      end
    end

    context "with invalid parameters" do
      it "returns error when follower_id is missing" do
        post "/api/v1/followings", params: { followed_id: followed.id }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("follower_id parameter is required")
      end

      it "returns error when followed_id is missing" do
        post "/api/v1/followings", params: { follower_id: follower.id }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("followed_id parameter is required")
      end

      it "returns error when follower doesn't exist" do
        post "/api/v1/followings", params: { follower_id: 999999, followed_id: followed.id }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("Follower user not found")
      end

      it "returns error when followed doesn't exist" do
        post "/api/v1/followings", params: { follower_id: follower.id, followed_id: 999999 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("Followed user not found")
      end

      it "returns error when trying to self-follow" do
        post "/api/v1/followings", params: { follower_id: follower.id, followed_id: follower.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("cannot follow yourself")
      end

      it "returns error when already following the user" do
        # Create the following relationship first
        create(:following, follower: follower, followed: followed)

        post "/api/v1/followings", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("already following")
      end
    end
  end
end
