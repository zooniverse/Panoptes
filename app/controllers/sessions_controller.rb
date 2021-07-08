class SessionsController < Devise::SessionsController
  skip_before_filter :verify_authenticity_token, only: [:destroy], if: :json_request?
  after_filter :set_csrf_headers, only: [:create, :destroy]
  after_filter :set_csrf_headers, only: :new, if: :json_request?

  def new
    respond_to do |format|
      format.html { super }
      format.json { login_options }
    end
  end

  def create
    respond_to do |format|
      format.html { super }
      format.json { create_from_json }
    end
  end

  def destroy
    respond_to do |format|
      format.html { super }
      format.json { destroy_from_json }
    end
  end

  private

  def create_from_json
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)
    yield resource if block_given?
    resource_scope = resource.class.where(id: resource.id)
    render status: 200, json: UserSerializer.resource({}, resource_scope, { include_private: true })
  end

  def destroy_from_json
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    yield if block_given?
    head :no_content
  end

  def login_options
    opts = { login: '/users/sign_in' }
    render status: 200, json: opts
  end

  def set_csrf_headers
    response.headers['X-CSRF-Param'] = request_forgery_protection_token.to_s
    response.headers['X-CSRF-Token'] = form_authenticity_token.to_s
  end
end
