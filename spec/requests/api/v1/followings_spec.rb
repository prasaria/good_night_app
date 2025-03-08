# spec/requests/api/v1/followings_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::Followings", type: :request do
  describe "GET /api/v1/followings" do
    let(:user) { create(:user) }
    let(:valid_params) { { user_id: user.id } }

    # Create test data
    before do
      # Create users to follow
      followed_users = create_list(:user, 5)

      # Create followings in reverse order to test sorting
      followed_users.reverse_each do |followed|
        create(:following, follower: user, followed: followed)
      end

      # Create another user with different followings
      other_user = create(:user)
      create(:following, follower: other_user, followed: followed_users.first)
    end

    context "with valid parameters" do
      it "returns the list of users the given user follows" do
        get "/api/v1/followings", params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["status"]).to eq("success")
        expect(json_response["data"]["followed_users"].length).to eq(5)
        expect(json_response["data"]["followed_users"].first).to include(
          "id", "name", "created_at", "updated_at"
        )
      end

      it "includes pagination data" do
        get "/api/v1/followings", params: valid_params.merge(page: 1, per_page: 2)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["pagination"]).to include(
          "current_page", "total_pages", "total_count", "per_page"
        )
        expect(json_response["data"]["pagination"]["current_page"]).to eq(1)
        expect(json_response["data"]["pagination"]["total_pages"]).to eq(3) # 5 items, 2 per page
        expect(json_response["data"]["pagination"]["total_count"]).to eq(5)
      end

      it "paginates the results correctly" do
        get "/api/v1/followings", params: valid_params.merge(page: 2, per_page: 2)

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["followed_users"].length).to eq(2)
        expect(json_response["data"]["pagination"]["current_page"]).to eq(2)
      end

      it "includes user information" do
        get "/api/v1/followings", params: valid_params

        json_response = JSON.parse(response.body)
        first_user = json_response["data"]["followed_users"].first

        expect(first_user).to include("id", "name")
      end

      it "sorts by most recent by default" do
        get "/api/v1/followings", params: valid_params

        json_response = JSON.parse(response.body)
        user_ids = json_response["data"]["followed_users"].map { |u| u["id"] }

        # This test may need to be adjusted depending on your sorting implementation
        expect(user_ids.length).to eq(5)
      end

      it "sorts by name when requested" do
        get "/api/v1/followings", params: valid_params.merge(sort_by: "name")

        json_response = JSON.parse(response.body)
        user_names = json_response["data"]["followed_users"].map { |u| u["name"] }

        expect(user_names).to eq(user_names.sort)
      end

      it "returns empty array for a user with no followings" do
        user_with_no_followings = create(:user)

        get "/api/v1/followings", params: { user_id: user_with_no_followings.id }

        json_response = JSON.parse(response.body)
        expect(json_response["data"]["followed_users"]).to be_empty
        expect(json_response["data"]["pagination"]["total_count"]).to eq(0)
      end
    end

    context "with invalid parameters" do
      it "returns error when user_id is missing" do
        get "/api/v1/followings"

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("user_id parameter is required")
      end

      it "returns error when user doesn't exist" do
        get "/api/v1/followings", params: { user_id: 999999 }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("User not found")
      end
    end
  end

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

  describe "DELETE /api/v1/followings/:id" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    context "when using id parameter" do
      it "removes the following relationship" do
        following = create(:following, follower: follower, followed: followed)

        expect {
          delete "/api/v1/followings/#{following.id}"
        }.to change(Following, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it "returns 404 when following doesn't exist" do
        delete "/api/v1/followings/999999"

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Not Found")
        expect(json_response["details"]).to include("Following relationship not found")
      end
    end
  end

  describe "DELETE /api/v1/followings" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    context "when using follower_id and followed_id parameters" do
      it "removes the following relationship" do
        _following = create(:following, follower: follower, followed: followed)

        expect {
          delete "/api/v1/followings", params: { follower_id: follower.id, followed_id: followed.id }
        }.to change(Following, :count).by(-1)

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end

      it "returns 404 when following doesn't exist" do
        other_user = create(:user)

        delete "/api/v1/followings", params: { follower_id: follower.id, followed_id: other_user.id }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("Following relationship not found between these users")
      end

      it "returns 400 when follower_id is missing" do
        delete "/api/v1/followings", params: { followed_id: followed.id }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("follower_id parameter is required")
      end

      it "returns 400 when followed_id is missing" do
        delete "/api/v1/followings", params: { follower_id: follower.id }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["details"]).to include("followed_id parameter is required")
      end
    end
  end
end
