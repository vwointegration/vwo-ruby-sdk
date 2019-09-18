# frozen_string_literal: true

class VWO
  # Abstract class encapsulating user profile service functionality.
  # Override with your own implementation for storing
  # And retrieving the user profile.

  class UserProfile
    # Abstract method, must be defined to fetch the
    # User profile dict corresponding to the user_id.
    #
    # @param[String]        :user_id            ID for user whose profile needs to be retrieved.
    # @return[Hash]         :user_profile_obj   Object representing the user's profile.
    #
    def lookup(_user_id); end

    # Abstract method, must be to defined to save
    # The user profile dict sent to this method.
    # @param[Hash]    :user_profile_obj     Object representing the user's profile.
    #
    def save(_user_profile_obj); end
  end
end
