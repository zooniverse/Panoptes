require "user_unsubscribe_message_verifier"

class User < ActiveRecord::Base
  include Activatable
  include PgSearch::Model
  include ExtendedCacheKey

  ALLOWED_LOGIN_CHARACTERS = '[\w\-\.]'
  USER_LOGIN_REGEX = /\A#{ ALLOWED_LOGIN_CHARACTERS }+\z/
  DUP_LOGIN_SANITATION_ATTEMPTS = 20

  # virtual attribute used on registration form for minors
  attr_accessor :minor_age

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  has_many :classifications, dependent: :restrict_with_exception
  has_many :collection_preferences, class_name: "UserCollectionPreference", dependent: :destroy
  has_many :project_preferences, class_name: "UserProjectPreference", dependent: :destroy
  has_many :oauth_applications, class_name: "Doorkeeper::Application", as: :owner, dependent: :destroy

  has_many :memberships, dependent: :destroy
  has_many :active_memberships, -> { active }, class_name: 'Membership'
  has_one :identity_membership, -> { identity }, class_name: 'Membership'
  has_one :avatar, -> { where(type: "user_avatar")}, class_name: "Medium", as: :linked
  has_one :profile_header, -> { where(type: "user_profile_header")}, class_name: "Medium", as: :linked

  has_many :user_groups, through: :active_memberships
  has_one :identity_group, through: :identity_membership,
    source: :user_group, class_name: "UserGroup", dependent: :destroy

  has_many :project_roles, through: :identity_group
  has_many :collection_roles, through: :identity_group
  has_many :user_seen_subjects, dependent: :destroy
  has_many :uploaded_subjects, class_name: "Subject", foreign_key: "upload_user_id", dependent: :restrict_with_exception
  has_many :subject_set_imports

  belongs_to :signup_project, class_name: 'Project', foreign_key: "project_id"

  cache_by_resource_method :uploaded_subjects_count

  before_validation :default_display_name, on: [:create, :update]
  before_validation :sync_identity_group, on: [:update]
  before_validation :setup_unsubscribe_token, on: [:create]
  before_validation :update_ouroboros_created

  validates :login, presence: true, format: { with: USER_LOGIN_REGEX }
  validates_uniqueness_of :login, case_sensitive: false
  validates :display_name, presence: true
  validates :unsubscribe_token, presence: true, uniqueness: true
  validates_inclusion_of :valid_email, in: [true, false], message: "must be true or false"

  validates_with IdentityGroupNameValidator

  after_create :set_zooniverse_id
  after_create :send_welcome_email, unless: :migrated
  before_create :set_ouroboros_api_key

  delegate :projects, to: :identity_group
  delegate :collections, to: :identity_group
  delegate :subjects, to: :identity_group
  delegate :owns?, to: :identity_group


  pg_search_scope :search_name,
    against: [:login],
    using: {
      tsearch: {
        dictionary: "english",
        tsvector_column: "tsv"
      }
    }

  pg_search_scope :fuzzy_search_login,
    against: [:login],
    using: { trigram: {} }

  pg_search_scope :full_search_login,
    against: [:login],
    using: {
      tsearch: {
        dictionary: "english",
        tsvector_column: "tsv"
      },
      trigram: {}
    },
    ranked_by: ":tsearch + (0.25 * :trigram)"

  def self.subset_selection(ending_in = 5)
    id_mod_10_remainder_ends_in = "id % 10 = ?"
    where(id_mod_10_remainder_ends_in, ending_in)
  end

  def self.dormant(window=14, query=User)
    DatabaseReplica.read("read_dormant_users_from_replica") do
      # devise trackable sets the current_sign_in_at on each login
      havent_signed_in_since = "date(now()) - date(current_sign_in_at) >= #{window}"
      query = query.where(valid_email: true)
      query = query.where(havent_signed_in_since)
      query = query.where(activated_state: User.activated_states[:active])
      query = query.where(global_email_communication: true)
      query = query.select(:id)
      query.find_each do |dormant_user|
        # A user's project preference (UPP) is updated
        # each time they classify on a project.
        # The last updated UPP is a proxy to a user's classification activity
        # and the query is much less expensive than classifications or recents
        #
        # Ideally this should move to a last_classifcation FK attribute on the
        # user which is updated in the classification lifecycle
        last_classified_upp = UserProjectPreference
          .where(user_id: dormant_user.id)
          .where.not(email_communication: nil)
          .order(updated_at: :desc)
          .first

        has_not_recently_classified =
          if last_classified_upp
            time_since_activity = Time.now.utc - last_classified_upp.updated_at
            time_since_activity >= window.to_i.days.to_i
          else
            true
          end

        if has_not_recently_classified
          yield(dormant_user)
        end
      end
    end
  end

  def self.reflect_on_association(association_name)
    case association_name.to_sym
    when :projects, :collections
      UserGroup.reflect_on_association(association_name)
    else
      super
    end
  end

  def self.find_for_database_authentication(warden_conditions = { })
    warden_conditions = warden_conditions.dup
    if login_value = warden_conditions.delete(:login).try(:downcase)
      arel_table = User.arel_table
      user = arel_table[:login].lower.eq(login_value)
      user = user.or(arel_table[:email].eq(login_value))
      self.where(warden_conditions.to_hash).where(user).first
    else
      where(warden_conditions.to_hash).first
    end
  end

  def self.sanitize_login(string)
    string
      .gsub(/\s+/, '_')
      .gsub(/[^#{ ALLOWED_LOGIN_CHARACTERS }]/, '')
  end

  def self.uniqueify(field, value)
    suffix = nil

    while where(field => "#{value}#{suffix}").present?
      suffix ||= 0
      suffix += SecureRandom.random_number(1000) # Don't want sequential numbers
    end

    "#{value}#{suffix}"
  end

  def self.user_from_unsubscribe_token(signature)
    login = UserUnsubscribeMessageVerifier.verify(signature)
    find_by_lower_login(login)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  # Overrides Devise built-in to add disabled state
  def self.send_reset_password_instructions(attributes = {})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if recoverable.persisted? && !recoverable.disabled? && !recoverable.email.blank?
      recoverable.send_reset_password_instructions
    end
    recoverable
  end

  def self.find_by_lower_login(login)
    find_by("lower(login) = ?", login.downcase)
  end

  def subject_limit
    super || Panoptes.max_subjects
  end

  def memberships_for(action, klass)
    membership_roles = UserGroup.roles_allowed_to_access(action, klass)
    active_memberships.where("roles && ARRAY[?]::varchar[]", membership_roles)
  end

  def password_required?
    super && hash_func != 'sha1'
  end

  def password=(new_password)
    super
    self.hash_func = 'bcrypt' if @password.present?
  end

  def valid_password?(password)
    case hash_func
    when 'bcrypt'
      super(password)
    when 'sha1'
      valid_sha1_password?(password)
    else
      false
    end
  end

  def active_for_authentication?
    return false if disabled?
    update_ouroboros_created
    ok_for_auth = changed? ? save : true
    ok_for_auth && super
  end

  def email_required?
    !disabled?
  end

  def receives_email?
    return false if disabled?
    return false if email.blank?
    valid_email
  end

  def build_identity_group
    default_display_name
    raise StandardError, "Identity Group Exists" if identity_group
    build_identity_membership(roles: ["group_admin"])
    identity_membership.build_user_group(display_name: display_name, name: login)
  end

  def is_admin?
    !!admin
  end

  def valid_sha1_password?(plain_password)
    worked = nil
    1.upto(25).each do |n|
      if encrypted_password == Sha1Encryption.encrypt(plain_password, password_salt, -n)
        worked = n
        logger.info "User #{id} is using sha1 password. Updating..."
        self.password = plain_password
        self.hash_func = 'bcrypt'
        setup_unsubscribe_token
        #unset the attribute to skip devise length validation
        self.password = nil
        self.save!
        break
      end
    end
    !!worked
  end

  def default_display_name
    self.display_name ||= login
  end

  def update_ouroboros_created
    if ouroboros_created
      counter = 0
      sanitized_login = User.sanitize_login(display_name)
      sanitized_login = panoptes_zoo_id if sanitized_login.blank?
      self.login = sanitized_login
      until no_other_logins_exist?(login) || counter == DUP_LOGIN_SANITATION_ATTEMPTS
        self.login = "#{ sanitized_login }-#{ counter += 1 }"
      end
      self.ouroboros_created = false
      build_identity_group
      setup_unsubscribe_token
    end
  end

  def non_identity_user_group_ids
    memberships.active.not_identity.pluck(:user_group_id)
  end

  def panoptes_zoo_id
    "panoptes-#{ id }"
  end

  def set_zooniverse_id
    self.zooniverse_id ||= panoptes_zoo_id
    if zooniverse_id_changed?
      self.update_column(:zooniverse_id, self.zooniverse_id)
    end
  end

  def setup_unsubscribe_token
    if self.login
      self.unsubscribe_token ||= UserUnsubscribeMessageVerifier.create_access_token(self.login)
    end
  end

  def send_welcome_email
    UserWelcomeMailerWorker.perform_async(id, project_id)
  rescue Timeout::Error, Redis::TimeoutError, Redis::CannotConnectError
    UserWelcomeMailerWorker.new.perform(id, project_id)
  end

  def set_ouroboros_api_key
    self.api_key = Digest::SHA1.hexdigest("#{ Time.now.utc }#{ email }")[0...20]
  end

  def sync_identity_group
    if identity_group
      identity_group.name = login if login_changed?
      identity_group.display_name = display_name if display_name_changed?
      identity_group.save!
    end
  end

  def no_other_logins_exist?(login)
    if user = User.find_by_lower_login(login)
      user.id == id
    else
      true
    end
  end

  def uploaded_subjects_count
    count = Rails.cache.fetch(subjects_count_cache_key, expires_in: subject_count_cache_expiry) do
      Subject.where(upload_user_id: id).count
    end
    count.to_i
  end

  def increment_subjects_count_cache
    Rails.cache.increment(subjects_count_cache_key)
  end

  def favorite_collections_for_project(project_id)
    collections.joins(:projects).where(favorite: true, projects: {id: project_id})
  end

  private

  def subjects_count_cache_key
    @subjects_count_cache_key ||= "User/#{id}/uploaded_subjects_count"
  end

  def subject_count_cache_expiry
    ENV.fetch("UPLOADED_SUBJECTS_COUNT_CACHE_EXPIRY", 1.hour).to_i.seconds
  end
end
