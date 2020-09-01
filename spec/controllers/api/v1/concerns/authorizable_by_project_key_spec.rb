shared_examples 'authorizable_by_project_key' do
  describe described_class, type: :controller do
    controller(described_class) do
      def index
        head 200
      end
    end

    let!(:project) { create(:project) }

    context 'when correct project key is present' do
      before do
        allow(controller).to receive(:project_key).and_return('key')
        allow(controller).to receive(:request_key).and_return('key')
        allow(controller).to receive(:project).and_return(project)

        project.regenerate_api_key
      end

      it 'sets authorization' do
        get :index
        expect(controller.authorized).to be_truthy
      end
    end

    context 'when correct project key is not present' do
      before do
        allow(controller).to receive(:authorized).and_call_original
        allow(controller).to receive(:project).and_return(project)
      end

      it 'does nothing' do
        get :index
        expect(controller.authorized).to be_falsey
      end
    end
  end
end
