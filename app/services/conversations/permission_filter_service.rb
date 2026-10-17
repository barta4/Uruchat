class Conversations::PermissionFilterService
  CONVERSATION_PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
  ].freeze

  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account, plan_hint_selective_filter: false)
    @conversations = conversations
    @user = user
    @account = account
    @plan_hint_selective_filter = plan_hint_selective_filter
  end

  def perform
    return conversations if user_role == 'administrator'
    return custom_role_conversations if custom_role_member?

    accessible_conversations
  end

  private

  def custom_role_member?
    account_user&.custom_role_id.present?
  end

  def custom_role_conversations
    permissions = account_user.custom_role.permissions
    conversation_permissions = permissions & CONVERSATION_PERMISSIONS

    return conversations.none if conversation_permissions.blank?
    return conversations if conversation_permissions.include?('conversation_manage')

    conditions = ['conversations.assignee_id = :user_id']
    values = { user_id: user.id }

    if conversation_permissions.include?('conversation_unassigned_manage')
      conditions << 'conversations.assignee_id IS NULL'
    end

    if conversation_permissions.include?('conversation_participating_manage')
      conditions << 'conversations.id IN (SELECT conversation_participants.conversation_id FROM conversation_participants
                      WHERE conversation_participants.user_id = :user_id AND conversation_participants.account_id = :account_id)'
      values[:account_id] = account.id
    end

    conversations.where(conditions.join(' OR '), values)
  end

  def accessible_conversations
    return hinted_accessible_conversations if @plan_hint_selective_filter

    conversations.where(inbox: user.inboxes.where(account_id: account.id))
  end

  # Same rows as accessible_conversations. `inbox_id + 0` keeps the planner from
  # driving the query through an inbox scan, which it grossly misestimates when a
  # highly selective filter (e.g. labels) is present on large accounts (CW-7787).
  def hinted_accessible_conversations
    conversations.where(
      '(conversations.inbox_id + 0) IN (
        SELECT inbox_members.inbox_id FROM inbox_members
        INNER JOIN inboxes ON inboxes.id = inbox_members.inbox_id
        WHERE inbox_members.user_id = :user_id AND inboxes.account_id = :account_id
      )',
      user_id: user.id, account_id: account.id
    )
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
