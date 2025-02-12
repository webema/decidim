# frozen_string_literal: true

module Decidim
  # A command with all the business logic to reject an invitation to belong to a
  # group.
  class RejectGroupInvitation < Decidim::Command
    # Public: Initializes the command.
    #
    # user_group - the UserGroup where the user has been invited
    # user - the User that has been invited
    def initialize(user_group, user)
      @user_group = user_group
      @user = user
    end

    # Executes the command. Broadcasts these events:
    #
    # - :ok when everything is valid.
    # - :invalid if we couldn't proceed.
    #
    # Returns nothing.
    def call
      return broadcast(:invalid) if membership.blank?

      reject_invitation

      broadcast(:ok)
    end

    private

    attr_reader :user_group, :user

    def reject_invitation
      membership.destroy!
    end

    def membership
      @membership ||= Decidim::UserGroupMembership.find_by(user:, user_group:, role: :invited)
    end
  end
end
