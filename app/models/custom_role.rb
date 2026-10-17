# == Schema Information
#
# Table name: custom_roles
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  permissions :text             default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_custom_roles_on_account_id  (account_id)
#

class CustomRole < ApplicationRecord
  belongs_to :account
  has_many :account_users, dependent: :nullify

  after_update_commit :invalidate_unread_counts, if: :saved_change_to_permissions?

  PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
    contact_manage
    report_manage
    knowledge_base_manage
  ].freeze

  validates :name, presence: true
  validate :permissions_must_be_known

  private

  def permissions_must_be_known
    unknown = permissions.to_a - PERMISSIONS
    errors.add(:permissions, "contains unknown permissions: #{unknown.join(', ')}") if unknown.any?
  end

  # Permission changes alter which conversations are visible to the role members,
  # so the filtered unread counts must be rebuilt for each affected user.
  def invalidate_unread_counts
    invalidator = ::Conversations::UnreadCounts::FilteredCountInvalidator.new(account)
    return unless invalidator.users_visibility_changed!(user_ids: account_users.pluck(:user_id))

    Rails.configuration.dispatcher.dispatch(ACCOUNT_CACHE_INVALIDATED, Time.zone.now, account: account, cache_keys: account.cache_keys)
  end
end
