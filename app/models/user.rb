class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name # Assuming the User model has a `name` field
      user.avatar_url = auth.info.image # Assuming the User model has an `avatar_url` field

      # Auto-confirm OAuth users
      user.skip_confirmation!
      user.confirm
    end
  end

  # Helper method for seeding users with confirmation
  def self.create_with_confirmation(attributes)
    user = User.new(attributes)
    user.skip_confirmation!
    user.confirm
    user.save
    user
  end
end
