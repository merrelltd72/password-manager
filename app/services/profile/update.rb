# frozen_string_literal: true

module Profile
  # Service object to handle profile updates, including user attributes and preferences.
  class Update
    def initialize(user:, params:)
      @user = user
      @params = params || {}
    end

    def call
      ActiveRecord::Base.transaction do
        update_user!
        update_preferences!
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    private

    def update_user!
      return unless @params.key?(:username)

      @user.update!(username: @params[:username])
    end

    def update_preferences!
      pref_params = @params[:preferences]
      return unless pref_params.present?

      preference = @user.user_preference || @user.build_user_preference
      preference.assign_attributes(
        timezone: pref_params[:timezone] || preference.timezone,
        date_format: pref_params[:date_format] || preference.date_format,
        generator_defaults: pref_params[:generator_defaults] || preference.generator_defaults,
        reminder_defaults: pref_params[:reminder_defaults] || preference.reminder_defaults
      )
      preference.save!
    end
  end
end
