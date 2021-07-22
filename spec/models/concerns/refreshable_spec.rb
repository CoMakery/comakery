shared_examples 'refreshable' do
  describe 'fresh?' do
    subject { described_class.fresh? }

    context 'without synced records' do
      it { is_expected.to be_nil }
    end

    context 'with synced records' do
      context 'synced more that 10 mins ago' do
        before do
          create(described_class.to_s.underscore.to_sym, status: :synced, synced_at: 11.minutes.ago)
        end

        it { is_expected.to be_falsey }
      end

      context 'synced more less 10 mins ago' do
        before do
          create(described_class.to_s.underscore.to_sym, status: :synced, synced_at: 2.minutes.ago)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.outdate_all' do
    subject { described_class.outdate_all }

    context 'update status for all records' do
      before do
        create(described_class.to_s.underscore.to_sym, status: :synced)
        create(described_class.to_s.underscore.to_sym, status: :synced)
      end

      it do
        subject
        expect(described_class.all.all?(&:outdated?)).to be true
      end
    end
  end
end
