require 'spec_helper'

describe PasswordsController, type: [ :controller, :mailer ] do
  before(:each) do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#edit" do
    context "when a redirect is configured" do
      it 'should redirect ' do
        test_base_url = "http://localhost:2727/#/reset-password"
        token = "asdfasdfasdf"
        get :edit, reset_password_token: token
        expect(response).to redirect_to("#{test_base_url}?reset_password_token=#{token}")
      end
    end
  end

  context "as json" do
    describe "#create" do
      before(:each) do
        request.env["HTTP_ACCEPT"] = "application/json"
        request.env["CONTENT_TYPE"] = "application/json"
      end

      let(:user) { create(:user) }
      let(:email_attributes) { user.attributes.slice("email") }
      let(:user_email_attrs) { { user: email_attributes } }

      it "should return 422 with no email" do
        post :create, user: { email: nil }
        expect(response.status).to eq(422)
      end

      context "using an email address that doesn't belong to a user" do

        before(:each) do
          post :create, user: { email: 'not_a_user@test.com' }
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should not send an email to the account email address" do
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end

      context "when the user is disabled" do
        let!(:disable_user) { user.disable! }

        it "should respond with 200" do
          post :create, user_email_attrs
          expect(response.status).to eq(200)
        end

        it "should not send an email to the account email address" do
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end

      context "using an email address that belongs to a user" do

        it "should queue the email for delayed sending" do
          prev_mailer = Devise.mailer
          Devise.mailer = Devise::BackgroundMailer
          expect { post :create, user_email_attrs }
            .to change { Sidekiq::Extensions::DelayedMailer.jobs.size }
            .from(0).to(1)
          Devise.mailer = prev_mailer
        end

        it "should return 200" do
          post :create, user_email_attrs
          expect(response.status).to eq(200)
        end

        it "should use devise to send the password reset email" do
          allow_any_instance_of(PasswordsController)
            .to receive(:successfully_sent?).and_return(true)
          expect(User)
            .to receive(:send_reset_password_instructions)
            .and_call_original
          post :create, user_email_attrs
        end

        it "should send an email" do
          post :create, user_email_attrs
          expect(ActionMailer::Base.deliveries).to_not be_empty
        end

        it "should send an email from the no-reply email address" do
          post :create, user_email_attrs
          email = ActionMailer::Base.deliveries.first
          expect(email.from).to include("no-reply@zooniverse.org")
        end

        it "should send an email to the account email address" do
          post :create, user_email_attrs
          email = ActionMailer::Base.deliveries.first
          expect(email.to).to include(user.email)
        end

        it "should contain the correct route url for the server" do
          post :create, user_email_attrs
          email = ActionMailer::Base.deliveries.first
          url = "https://panoptes_test.zooniverse.org/users/password/edit?reset_password_token="
          expect(email.body.raw_source).to include(url)
        end
      end
    end

    describe "#update" do
      before(:each) do
        request.env["HTTP_ACCEPT"] = "application/json"
        request.env["CONTENT_TYPE"] = "application/json"
      end

      let(:user) { create(:user) }
      let(:new_password) { "87654321" }
      let(:passwords) do
        { password: new_password, password_confirmation: new_password }
      end

      context "when not supplying a valid reset token" do
        before do
          put :update, user: passwords.merge(reset_password_token: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        end

        it "should return return 422 and a meaningful error response body" do
          expect(response.status).to eq(422)
          error = JSON.parse(response.body)["errors"].first
          expect(error["message"]).to eq("Reset password token is invalid")
        end
      end

      context "when supplying a valid reset token" do
        let(:valid_token) { user.send_reset_password_instructions }
        let(:valid_attrs) { { user: passwords.merge(reset_password_token: valid_token) } }

        context "with a database user" do
          it "should return 200" do
            put :update, valid_attrs
            expect(response.status).to eq(200)
          end

          it "should update the password" do
            put :update, valid_attrs
            user.reload
            expect(user.valid_password?(new_password)).to eq(true)
          end

          context "when supplying a invalid new password" do
            let(:passwords) do
              short = "1234"
              { password: short, password_confirmation: short }
            end

            it "should return a meaningful error response body" do
              put :update, user: passwords.merge(reset_password_token: valid_token)
              expect(response.status).to eq(422)
              error = JSON.parse(response.body)["errors"].first
              expect(error["message"]).to eq("Password is too short (minimum is 8 characters)")
            end
          end
        end
      end
    end
  end

  context "as html" do

    before(:each) do
      request.env["HTTP_ACCEPT"] = "text/html"
    end

    describe "#update" do

      let(:user) { create(:user) }
      let(:new_password) { "87654321" }
      let(:passwords) do
        { password: new_password, password_confirmation: new_password }
      end

      context "when not supplying a valid reset token" do
        before(:each) do
          put :update, user: { reset_password_token: "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        end

        it "should return 200" do
          expect(response.status).to eq(200)
        end

        it "should not have updated the password" do
          user.reload
          expect(user.valid_password?(new_password)).to_not eq(true)
        end
      end

      context "when supplying a valid reset token" do
        let(:valid_token) { user.send_reset_password_instructions }

        context "with a database user" do

          before(:each) do
            put :update, user: passwords.merge(reset_password_token: valid_token)
          end

          it "should return 302 redirect" do
            expect(response.status).to eq(302)
          end

          it "should update the password" do
            user.reload
            expect(user.valid_password?(new_password)).to eq(true)
          end
        end
      end
    end
  end
end
