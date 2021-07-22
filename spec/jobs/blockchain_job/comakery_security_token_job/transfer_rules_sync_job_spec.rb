require 'rails_helper'

RSpec.describe BlockchainJob::ComakerySecurityTokenJob::TransferRulesSyncJob, type: :job do
  let(:token) do
    create(
      :token,
      _token_type: :comakery_security_token,
      symbol: 'TEST',
      decimal_places: 0,
      contract_address: '0x1D1592c28FFF3d3E71b1d29E31147846026A0a37',
      _blockchain: 'ethereum_ropsten',
      ethereum_network: 'ropsten'
    )
  end

  example 'create reg groups and transfer rules' do
    expect(token.reg_groups.count).to eq 1
    expect(token.transfer_rules.count).to be_zero

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/filtered_logs") do
      described_class.perform_now(token)
    end

    token.reload
    expect(token.reg_groups.count).to eq 10
    expect(token.transfer_rules.count).to eq 16

    transfer_rule = token.transfer_rules.first
    expect(transfer_rule.token_id).to eq token.id
    expect(transfer_rule.sending_group).to be_truthy
    expect(transfer_rule.receiving_group).to be_truthy
    expect(transfer_rule.lockup_until).to be > Time.zone.at(0)
    expect(transfer_rule.synced_at).to be > 5.seconds.ago
    expect(transfer_rule.status).to eq 'synced'

    reg_group = token.reg_groups.order(blockchain_id: :desc).first
    expect(reg_group.token_id).to eq token.id
    expect(reg_group.name).to eq '10'
    expect(reg_group.blockchain_id).to eq 10

    permanently_locked_transfer_rules = token.transfer_rules.where('lockup_until = 0 or lockup_until is null')
    expect(permanently_locked_transfer_rules.count).to be_zero
  end

  example 'outdate existing rules and do not overwrite reg groups' do
    reg_group = RegGroup.create!(name: 'Named group', blockchain_id: 1, token: token)
    reg_group_zero = RegGroup.find_by!(token: token, blockchain_id: 0)
    transfer_rule = TransferRule.create!(token: token, sending_group: reg_group_zero, receiving_group: reg_group, lockup_until: Time.current, status: 'synced')

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/filtered_logs") do
      described_class.perform_now(token)
    end

    token.reload
    expect(token.reg_groups.count).to eq 10
    expect(token.transfer_rules.count).to eq 17

    reg_group.reload
    expect(reg_group.token_id).to eq token.id
    expect(reg_group.name).to eq 'Named group'
    expect(reg_group.blockchain_id).to eq 1

    expect(transfer_rule.reload.status).to eq 'outdated'

    new_transfer_rule = TransferRule.find_by!(token: token, sending_group: reg_group_zero, receiving_group: reg_group, status: 'synced')
    expect(new_transfer_rule.lockup_until).to eq Time.zone.parse('1970-01-01 00:00:01')
    expect(new_transfer_rule.synced_at).to be > 5.seconds.ago
  end

  example 'outdated existing rule if last lockup_until in blockchain is 0' do
    allow_any_instance_of(described_class).to receive(:filtered_events).and_return(
      # 0 => 0 with lockup_until=0
      [
        {
          'address' => '0x1d1592c28fff3d3e71b1d29e31147846026a0a37',
          'blockHash' => '0x8af77a01acae4e79b51e90d78c7eeac4ee653a0d5991fde71b5d5fa692fe6b68',
          'blockNumber' => '0x63d00e',
          'data' => '0x0000000000000000000000000000000000000000000000000000000000000000',
          'logIndex' => '0x11',
          'removed' => false,
          'topics' =>
          %w[0x5845e315015ee03f0d4ab1d198172b4f733609dc3de8b957ae1d86c874030189
             0x00000000000000000000000066ebd5cdf54743a6164b0138330f74dce436d842
             0x0000000000000000000000000000000000000000000000000000000000000000
             0x0000000000000000000000000000000000000000000000000000000000000000],
          'transactionHash' => '0xe61ed61e1450c3f4a72039c838dda93b29a7ac367f18240ae7b5d8a886126739',
          'transactionIndex' => '0x2d'
        }
      ]
    )
    reg_group_zero = RegGroup.find_by!(token: token, blockchain_id: 0)
    transfer_rule = TransferRule.create!(token: token, sending_group: reg_group_zero, receiving_group: reg_group_zero, lockup_until: Time.current, status: 'synced')
    expect(transfer_rule.lockup_until.to_i).to be_positive

    described_class.perform_now(token)

    expect(transfer_rule.reload.status).to eq 'outdated'

    new_transfer_rule = TransferRule.find_by(token: token, sending_group: reg_group_zero, receiving_group: reg_group_zero)
    expect(new_transfer_rule.status).to eq 'outdated' # outdate new rule with lockup_until=0
  end

  example 'with empty results' do
    allow_any_instance_of(described_class).to receive(:filtered_events).and_return([])

    described_class.perform_now(token)

    token.reload
    expect(token.reg_groups.count).to eq 1
    expect(token.transfer_rules.count).to be_zero
  end
end
