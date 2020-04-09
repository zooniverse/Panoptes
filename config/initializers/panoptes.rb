module Panoptes
  def self.lifecycled_live_window
    return @lifecycled_live_window if @lifecycled_live_window
    window = ENV["LIVE_WINDOW"].to_i
    @lifecycled_live_window = (window == 0 ? 15 : window)
  end

  def self.disable_lifecycle_worker
    Panoptes.flipper[:disable_lifecycle_worker].enabled?
  end

  def self.pg_statement_timeout
    ENV.fetch('PG_STATEMENT_TIMEOUT', 300000)
  end

  def self.user_project_recents_limit
    ENV.fetch('USER_PROJECT_RECENTS_LIMIT', 50)
  end
end
