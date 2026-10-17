require 'rails_helper'

RSpec.describe CustomRole, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'is valid with a name and known permissions' do
      role = build(:custom_role, account: account, name: 'Support Agent', permissions: %w[conversation_manage contact_manage])
      expect(role).to be_valid
    end

    it 'is invalid without a name' do
      role = build(:custom_role, account: account, name: nil)
      expect(role).not_to be_valid
      expect(role.errors[:name]).to be_present
    end

    it 'is invalid with unknown permissions' do
      role = build(:custom_role, account: account, permissions: %w[conversation_manage made_up_permission])
      expect(role).not_to be_valid
      expect(role.errors[:permissions]).to be_present
    end
  end

  describe '#destroy' do
    it 'nullifies the custom role of account users' do
      role = create(:custom_role, account: account, permissions: %w[contact_manage])
      agent = create(:user, account: account, role: :agent)
      agent.account_users.find_by(account: account).update!(custom_role_id: role.id)

      role.destroy

      expect(agent.account_users.find_by(account: account).reload.custom_role_id).to be_nil
    end
  end
end
