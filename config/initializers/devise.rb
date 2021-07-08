Devise.setup do |config|
  config.mailer_sender = 'no-reply@zooniverse.org'

  require 'devise/orm/active_record'

  config.authentication_keys = [ :login ]
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 10
  config.reconfirmable = true
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.paranoid = true
  config.sign_out_via = :delete

  # MAILER
  require 'devise_mailer/background_mailer'
  config.mailer = "Devise::BackgroundMailer"
end
