require 'rails_helper'

RSpec.describe 'Custom role permissions', type: :policy do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  def context_for(user)
    { user: user, account: account, account_user: user.account_users.find_by(account: account) }
  end

  def custom_role_agent(permissions)
    role = create(:custom_role, account: account, permissions: permissions)
    agent = create(:user, account: account, role: :agent)
    agent.account_users.find_by(account: account).update!(custom_role_id: role.id)
    agent
  end

  describe 'ConversationPolicy#show?' do
    context 'when the custom role grants conversation_manage' do
      let(:agent) { custom_role_agent(%w[conversation_manage]) }

      it 'allows access to any conversation' do
        expect(ConversationPolicy).to permit(context_for(agent), conversation)
      end
    end

    context 'when the custom role grants conversation_unassigned_manage' do
      let(:agent) { custom_role_agent(%w[conversation_unassigned_manage]) }

      it 'allows access to unassigned conversations' do
        conversation.update!(assignee_id: nil)
        expect(ConversationPolicy).to permit(context_for(agent), conversation)
      end

      it 'allows access to conversations assigned to the agent' do
        conversation.update!(assignee_id: agent.id)
        expect(ConversationPolicy).to permit(context_for(agent), conversation)
      end

      it 'denies access to conversations assigned to someone else' do
        conversation.update!(assignee_id: create(:user, account: account).id)
        expect(ConversationPolicy).not_to permit(context_for(agent), conversation)
      end
    end

    context 'when the custom role grants conversation_participating_manage' do
      let(:agent) { custom_role_agent(%w[conversation_participating_manage]) }

      it 'allows access when the agent is a participant' do
        create(:inbox_member, user: agent, inbox: inbox)
        create(:conversation_participant, conversation: conversation, account: account, user: agent)
        expect(ConversationPolicy).to permit(context_for(agent), conversation)
      end

      it 'allows access to conversations assigned to the agent' do
        conversation.update!(assignee_id: agent.id)
        expect(ConversationPolicy).to permit(context_for(agent), conversation)
      end

      it 'denies access to unassigned conversations' do
        conversation.update!(assignee_id: nil)
        expect(ConversationPolicy).not_to permit(context_for(agent), conversation)
      end
    end

    context 'when the custom role has no conversation permissions' do
      let(:agent) { custom_role_agent(%w[contact_manage]) }

      it 'denies access even with inbox membership' do
        create(:inbox_member, user: agent, inbox: inbox)
        expect(ConversationPolicy).not_to permit(context_for(agent), conversation)
      end
    end

    context 'when the agent has no custom role' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'keeps the default inbox based access' do
        create(:inbox_member, user: agent, inbox: inbox)
        expect(ConversationPolicy).to permit(context_for(agent), conversation)
      end
    end
  end

  describe 'ContactPolicy' do
    it 'allows contact actions with contact_manage' do
      agent = custom_role_agent(%w[contact_manage])
      expect(ContactPolicy).to permit(context_for(agent), Contact.new)
    end

    it 'denies contact actions without contact_manage' do
      agent = custom_role_agent(%w[conversation_manage])
      expect(ContactPolicy).not_to permit(context_for(agent), Contact.new)
    end

    it 'keeps contact actions allowed for plain agents' do
      agent = create(:user, account: account, role: :agent)
      expect(ContactPolicy).to permit(context_for(agent), Contact.new)
    end
  end

  describe 'ReportPolicy#view?' do
    it 'allows reports with report_manage' do
      agent = custom_role_agent(%w[report_manage])
      expect(ReportPolicy).to permit(context_for(agent), :report)
    end

    it 'denies reports without report_manage' do
      agent = custom_role_agent(%w[contact_manage])
      expect(ReportPolicy).not_to permit(context_for(agent), :report)
    end
  end

  describe 'ArticlePolicy#update?' do
    it 'allows articles with knowledge_base_manage' do
      agent = custom_role_agent(%w[knowledge_base_manage])
      expect(ArticlePolicy).to permit(context_for(agent), Article.new)
    end

    it 'denies articles without knowledge_base_manage' do
      agent = custom_role_agent(%w[contact_manage])
      expect(ArticlePolicy).not_to permit(context_for(agent), Article.new)
    end
  end

  describe 'AccountUser#permissions' do
    it 'returns the role permissions plus the custom_role marker' do
      agent = custom_role_agent(%w[contact_manage])
      expect(agent.account_users.find_by(account: account).permissions).to contain_exactly('contact_manage', 'custom_role')
    end

    it 'keeps administrator permissions' do
      admin = create(:user, account: account, role: :administrator)
      expect(admin.account_users.find_by(account: account).permissions).to eq(['administrator'])
    end
  end
end
