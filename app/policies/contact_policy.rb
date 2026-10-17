class ContactPolicy < ApplicationPolicy
  def index?
    has_permission?('contact_manage')
  end

  def active?
    has_permission?('contact_manage')
  end

  def import?
    @account_user.administrator?
  end

  def export?
    @account_user.administrator?
  end

  def search?
    has_permission?('contact_manage')
  end

  def filter?
    has_permission?('contact_manage')
  end

  def update?
    has_permission?('contact_manage')
  end

  def contactable_inboxes?
    has_permission?('contact_manage')
  end

  def destroy_custom_attributes?
    has_permission?('contact_manage')
  end

  def show?
    has_permission?('contact_manage')
  end

  def create?
    has_permission?('contact_manage')
  end

  def avatar?
    has_permission?('contact_manage')
  end

  def destroy?
    @account_user.administrator?
  end
end

ContactPolicy.prepend_mod_with('ContactPolicy')
