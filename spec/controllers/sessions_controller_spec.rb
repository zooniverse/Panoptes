require 'spec_helper'

describe SessionsController, type: :controller do
  let!(:users) { create_list(:user, 2) }
  let(:user) { users.first }

  context "using json", :zoo_home_user do
    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/json"
      request.env["CONTENT_TYPE"] = "application/json"
      request.env["devise.mapping"] = Devise.mappings[:user]
    end

    describe "#create" do
      %w(login email).each do |attr|
        context "with login as #{ attr }" do
          let(:params) do
            { password: user.password, login: user.send(attr) }
          end

          it 'should respond with the user object' do
            post :create, user: params
            expect(json_response).to include('users')
          end

          it 'should respond with a 200' do
            post :create, user: params
            expect(response.status).to eq(200)
          end

          it 'should sign in the user' do
            expect(controller).to receive(:sign_in)
            post :create, user: params
          end

          it "should ignore #{ attr } case" do
            expect(controller).to receive(:sign_in)
            params[:login] = user.send(attr).upcase
            post :create, user: params
          end
        end
      end
    end

    describe "#destroy" do
      context "a signed in user" do
        before(:each) do
          request.env['devise.user'] = user
          sign_in user
        end

        it 'should return no-content' do
          delete :destroy
          expect(response.status).to eq(204)
        end

        it 'should sign out the user' do
          expect(controller).to receive(:sign_out)
          delete :destroy
        end
      end
    end

    describe "#new" do
      before(:each) do
        get :new
      end

      it 'should return 200' do
        expect(response.status).to eq(200)
      end

      it 'should return a json response of login routes' do
        expect(json_response).to include('login')
      end
    end
  end
end
