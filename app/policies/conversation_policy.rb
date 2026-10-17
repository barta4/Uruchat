class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def destroy?
    administrator?
  end

  def show?
    return true if administrator? || agent_bot?
    return custom_role_conversation_access? if custom_role_member?

    inbox_access? || team_access?
  end

  private

  def custom_role_conversation_access?
    return true if has_permission?('conversation_manage')
    return true if assigned_to_user? && conversation_permission_holder?
    return true if has_permission?('conversation_unassigned_manage') && record.assignee_id.blank?
    return true if has_permission?('conversation_participating_manage') && participant?

    false
  end

  def conversation_permission_holder?
    %w[conversation_manage conversation_unassigned_manage conversation_participating_manage].any? { |permission| has_permission?(permission) }
  end

  def administrator?
    account_user&.administrator?
  end

  def agent_bot?
    user.is_a?(AgentBot)
  end

  def inbox_access?
    user.inboxes.where(account_id: account&.id).exists?(id: record.inbox_id)
  end

  def team_access?
    return false if record.team_id.blank?

    user.teams.where(account_id: account&.id).exists?(id: record.team_id)
  end

  def assigned_to_user?
    record.assignee_id == user.id
  end

  def participant?
    record.conversation_participants.exists?(user_id: user.id)
  end
end

ConversationPolicy.prepend_mod_with('ConversationPolicy')
