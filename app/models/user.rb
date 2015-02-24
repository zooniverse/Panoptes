class User < ActiveRecord::Base
  include Activatable
  include Linkable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook, :gplus]

  has_many :classifications
  has_many :authorizations
  has_many :collection_preferences, class_name: "UserCollectionPreference"
  has_many :project_preferences, class_name: "UserProjectPreference"
  has_many :oauth_applications, class_name: "Doorkeeper::Application", as: :owner

  has_many :memberships
  has_many :active_memberships, -> { active }, class_name: 'Membership'
  has_one :identity_membership, -> { identity }, class_name: 'Membership'

  has_many :user_groups, through: :active_memberships
  has_one :identity_group, through: :identity_membership,
                          source: :user_group,
                          class_name: "UserGroup"

  has_many :project_roles, through: :identity_group
  has_many :collection_roles, through: :identity_group

  validates :display_name, presence: true, uniqueness: { case_sensitive: false },
            format: { without: /\$|@|\s+/ }
  validates_length_of :password, within: 8..128, allow_blank: true,
                      unless: :migrated_user?

  validates_with IdentityGroupNameValidator

  delegate :projects, to: :identity_group
  delegate :collections, to: :identity_group
  delegate :subjects, to: :identity_group
  delegate :owns?, to: :identity_group

  can_be_linked :membership, :all
  can_be_linked :user_group, :all
  can_be_linked :user_subject_queue, :all
  can_be_linked :user_project_preference, :all
  can_be_linked :user_collection_preference, :all
  can_be_linked :project, :scope_for, :update, :user
  can_be_linked :collection, :scope_for, :update, :user

  attr_accessor :migrated_user

  def memberships_for(action, klass)
    membership_roles = UserGroup.roles_allowed_to_access(action, klass)
    active_memberships.where.overlap(roles: membership_roles)
  end

  def self.scope_for(action, user, opts={})
    case action
    when :show, :index
      active
    else
      where(id: user.id)
    end
  end

  def self.from_omniauth(auth_hash)
    auth = Authorization.from_omniauth(auth_hash)
    auth.user ||= create do |u|
      u.email = auth_hash.info.email
      u.password = Devise.friendly_token[0,20]
      name = auth_hash.info.name
      u.display_name = StringConverter.replace_spaces(name)
      u.build_identity_group
      u.authorizations << auth
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

  def password_required?
    super && hash_func != 'sha1'
  end

  def valid_password?(password)
    if hash_func == 'bcrypt'
      super(password)
    elsif hash_func == 'sha1'
      if encrypted_password == sha1_encrypt(password)
        logger.info "User #{id} is using sha1 password. Updating..."
        self.password = password
        self.hash_func = 'bcrypt'
        self.save
        true
      else
        false
      end
    else
      false
    end
  end

  def active_for_authentication?
    !disabled? && super
  end

  def email_required?
    authorizations.blank? && !disabled?
  end

  def email_changed?
    authorizations.blank?
  end

  def build_identity_group
    raise StandardError, "Identity Group Exists" if identity_group
    build_identity_membership
    identity_membership.build_user_group(display_name: display_name)
  end

  def is_admin?
    !!admin
  end

  protected

  def migrated_user?
    !!migrated_user
  end

  def sha1_encrypt(plain_password)
    bytes = plain_password.each_char.inject(''){ |bytes, c| bytes + c + "\x00" }
    concat = Base64.decode64(password_salt).force_encoding('utf-8') + bytes
    sha1 = Digest::SHA1.digest concat
    Base64.encode64(sha1).strip
  end
end
