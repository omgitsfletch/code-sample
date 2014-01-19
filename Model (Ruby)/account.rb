require 'bcrypt'

class Account < ActiveRecord::Base
	belongs_to :account_status
	belongs_to :account_type

	attr_accessor :password
	attr_accessor :pin

	# Checks password against the confirmation, and ensures a length of 6-50 characters. If this is a new user object, it MUST have a valid password to be saved.
	# However, if this is an existing record, it can be saved without a password change, but will perform validation if either the password OR confirmation is present
	validates :password,
						confirmation: { :message => 'Password must match confirmation.' },
						presence: { :message => 'Password is required.' },
						length: { :minimum => 6, :maximum => 50, :message => 'Password must be between 6 and 50 characters.' },
						if: Proc.new { |rec| rec.password_present? || rec.new_record? }
	validates :password_confirmation,
						presence: { :message => 'Password must match confirmation.' },
						if: Proc.new { |rec| rec.password_present? || rec.new_record? }

	validates :pin,
						presence: { :message => 'Pin is required.' },
						format: { with: /\A[0-9]+\z/, message: 'Pin must be numbers only.' },
						length: { :minimum => 4, :maximum => 16, :message => 'Pin must be between 4 and 16 characters.' },
						on: :create

	# Before every save, call method that can generate a salt if necessary, and saves a new password hash if needed
	before_save :hash_password

	# Used on validators to determine if either attribute was defined, in which case validations should run, whether this is a new record or not
	def password_present?
		!self.password.blank? || !self.password_confirmation.blank?
	end

	def make_salt
		self.salt = BCrypt::Engine.generate_salt
	end

	def hash_password
		if self.salt.blank?
			self.make_salt
		end

		# Only save PIN hash if this is a new record
		if !self.pin.blank? && self.new_record?
			self.crypted_pin = BCrypt::Engine.hash_secret(self.pin, self.salt)
		end

		# Always save password hash, as long as password is present
		if !self.password.blank?
			self.crypted_pass = BCrypt::Engine.hash_secret(self.password, self.salt)
		end
	end

	def self.authenticate(username, password)
		begin
			user = Account.find_by_username(username)

			# Check if this user is currently locked out
			if user.failed_logins >= Constants::Accounts::LOGIN_LOCK_FAILED_COUNT
				# If the lock should have expired, unlock the account before attempting authentication
				if Time.now >= user.login_lock_expires_at
					user.failed_logins = 0
					user.login_lock_expires_at = nil
				else
					# Lock has not expired, fail without attempting authentication 
					raise AccountStillLockedException
				end
			end

			# Attempt authentication
			if (BCrypt::Password.new(user.crypted_pass) == password)
				# Even if the user had some failed logins, since they were successful reset that count
				user.failed_logins = 0
				user.last_login_at = Time.now
				user.save

				return { :success => true, :user => user }
			else
				# Login failed, increment failed login count, and place lock if needed
				if user.failed_logins.blank?
					user.failed_logins = 1
				else
					user.failed_logins += 1
				end

				if user.failed_logins >= Constants::Accounts::LOGIN_LOCK_FAILED_COUNT
					user.login_lock_expires_at = (Time.now + Constants::Accounts::LOGIN_LOCK_TIME_SEC)
					user.save
					raise AccontLoginFailedAndLockedException
				else
					user.save
					raise AccountLoginFailedException
				end
			end
		# For now, catch all exceptions and render generic failure message
		rescue Exception => e
			message = "Login attempt for username '#{username}' failed."
		  Rails.logger.error message
		  return { :success => false, :message => message }
		end
	end
end