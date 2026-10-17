class CategoryPolicy < ApplicationPolicy
  def index?
    @account.users.include?(@user)
  end

  def update?
    has_permission?('knowledge_base_manage')
  end

  def show?
    has_permission?('knowledge_base_manage')
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

  def reorder?
    has_permission?('knowledge_base_manage')
  end
end

CategoryPolicy.prepend_mod_with('CategoryPolicy')
