require 'rails_helper'

RSpec.describe 'Custom Roles API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/custom_roles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_roles"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      before { create_list(:custom_role, 2, account: account, permissions: %w[contact_manage]) }

      it 'returns all custom roles for the account' do
        get "/api/v1/accounts/#{account.id}/custom_roles",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.length).to eq(2)
        expect(json_response.first.keys).to include('id', 'name', 'description', 'permissions')
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_roles",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/custom_roles' do
    it 'creates a custom role for the account' do
      expect do
        post "/api/v1/accounts/#{account.id}/custom_roles",
             headers: admin.create_new_auth_token,
             params: { custom_role: { name: 'Support', description: 'Support agents', permissions: %w[contact_manage] } },
             as: :json
      end.to change(CustomRole, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['name']).to eq('Support')
      expect(response.parsed_body['permissions']).to eq(%w[contact_manage])
    end

    it 'rejects unknown permissions' do
      post "/api/v1/accounts/#{account.id}/custom_roles",
           headers: admin.create_new_auth_token,
           params: { custom_role: { name: 'Bad', permissions: %w[made_up] } },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/custom_roles/:id' do
    let(:custom_role) { create(:custom_role, account: account, permissions: %w[contact_manage]) }

    it 'updates the permissions' do
      put "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
          headers: admin.create_new_auth_token,
          params: { custom_role: { permissions: %w[conversation_manage report_manage] } },
          as: :json

      expect(response).to have_http_status(:success)
      expect(custom_role.reload.permissions).to eq(%w[conversation_manage report_manage])
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/custom_roles/:id' do
    let(:custom_role) { create(:custom_role, account: account, permissions: %w[contact_manage]) }

    it 'destroys the custom role' do
      delete "/api/v1/accounts/#{account.id}/custom_roles/#{custom_role.id}",
             headers: admin.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:success)
      expect(CustomRole.exists?(custom_role.id)).to be false
    end
  end
end
