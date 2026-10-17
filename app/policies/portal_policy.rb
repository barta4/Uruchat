class PortalPolicy < ApplicationPolicy
  def index?
    @account.users.include?(@user)
  end

  def update?
    has_permission?('knowledge_base_manage')
  end

  def show?
    @account.users.include?(@user)
  end

  def edit?
    has_permission?('knowledge_base_manage')
  end

  def create?
    has_permission?('knowledge_base_manage')
  end

  def destroy?
    @account_user.administrator?
  end

  def logo?
    has_permission?('knowledge_base_manage')
  end

  def send_instructions?
    has_permission?('knowledge_base_manage')
  end

  def ssl_status?
    @account.users.include?(@user)
  end
end

PortalPolicy.prepend_mod_with('PortalPolicy')
