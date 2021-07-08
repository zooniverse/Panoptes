require 'spec_helper'

describe "user sign in sessions", type: :request do

  context "json request" do

    shared_examples "it returns the login options and csrf headers" do
      before(:each) do
        get_sign_in
      end

      it "should return the login options" do

        aggregate_failures "success" do
          expect(response.status).to eq(200)
          expect(json_response).to include('login')
        end
      end

      it "should return the csrf headers" do
        has_keys = %w( X-CSRF-Param X-CSRF-Token ).map do |key|
          response.headers.has_key?(key)
        end.uniq
        expect(has_keys).to eq([true])
      end
    end

    let(:get_sign_in) { get new_user_session_path, nil, json_defaults }
    let(:json_defaults) do
      {
        "HTTP_ACCEPT" => "application/json",
        "CONTENT_TYPE" => "application/json"
      }
    end

    context "when unauthenticated" do
      it_behaves_like "it returns the login options and csrf headers"
    end

    context "when authenticated" do
      before(:each) do
        sign_in_as_a_valid_user(:user)
      end
      it_behaves_like "it returns the login options and csrf headers"
    end
  end

  context "html request" do
    let(:get_sign_in) { get new_user_session_path }

    context "when unauthenticated" do

      it "should return the login page" do
        get_sign_in
        aggregate_failures "success" do
          expect(response.status).to eq(200)
          expect(response.body).to include("form", "Sign in")
        end
      end
    end

    context "when authenticated" do
      before(:each) do
        sign_in_as_a_valid_user(:user)
        get_sign_in
      end

      it "should redirect" do
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
