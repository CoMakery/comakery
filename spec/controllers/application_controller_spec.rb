require 'rails_helper'

class FoosController < ApplicationController; end

describe ApplicationController do
  controller FoosController do
    skip_before_action :require_login

    def index
      raise ActiveRecord::RecordNotFound
    end

    def new
      raise Slack::Web::Api::Error, 'boom'
    end

  end

  describe 'errors' do
    describe 'ActiveRecord::RecordNotFound' do
      it 'redirects to 404 page' do
        get :index

        expect(response).to redirect_to '/404.html'
      end
    end

    describe 'Slack::Web::Api::Error' do
      it 'redirects to logout page' do
        expect(Rails.logger).to receive(:error)
        session[:account_id] = 432

        get :new

        expect(session).not_to have_key(:account_id)
        expect(response).to redirect_to root_url
        expect(flash[:error]).to eq('Error talking to Slack, sorry!')
      end
    end
  end
end
