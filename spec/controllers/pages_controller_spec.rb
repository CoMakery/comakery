require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'contribution_licenses' do
    %w[CP RP].each do |type|
      it "renders the latest version of #{type} license" do
        get :contribution_licenses, params: { type: type }
        expect(response).to render_template('pages/contribution_licenses')
        expect(assigns[:license_md]).to include("#{type}-1.0.0")
      end
    end

    it 'redirects to 404 if license with given type is not found' do
      get :contribution_licenses, params: { type: 'dummy' }
      expect(response).to redirect_to('/404.html')
    end
  end

  it 'access e-sign disclosure' do
    get :e_sign_disclosure
    expect(response).to render_template('pages/e_sign_disclosure')
  end

  it 'access privacy policy' do
    get :privacy_policy
    expect(response).to render_template('pages/privacy_policy')
  end

  it 'access prohibited use policy' do
    get :prohibited_use
    expect(response).to render_template('pages/prohibited_use')
  end

  it 'access user agreement' do
    # allow(ENV).to receive(:[]).with('BASIC_AUTH').and_return('test:test')
    get :user_agreement
    expect(response).to render_template('pages/user_agreement')
  end

  it 'access featured page' do
    get :featured
    expect(response.status).to eq(200)
  end

  it 'basic auth' do
    ENV.stub(:key?) { 'test:test' }
    ENV.stub(:fetch) { 'test:test' }
    get :featured
  end

  it 'redirects from styleguide page' do
    get :styleguide
    expect(response.status).to eq(302)
  end

  it 'returns styleguide page in dev env' do
    env_backup = Rails.env
    Rails.env  = 'development'
    get :styleguide
    Rails.env = env_backup
    expect(response.status).to eq(200)
    expect(response).to render_template('pages/styleguide')
    expect(response).to render_template('layouts/layout_new_styling')
  end

  it 'is unavailable_for_whitelabel' do
    create :active_whitelabel_mission

    get :featured
    expect(response).to redirect_to(new_session_url)
  end
end
