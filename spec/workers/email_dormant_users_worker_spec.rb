require 'spec_helper'

describe EmailDormantUsersWorker do
  let(:worker) { described_class.new }

  it "should be not retry on failure" do
    retry_count = worker.class.get_sidekiq_options['retry']
    expect(retry_count).to eq(0)
  end

  it "should raise error if running on staging" do
    allow(Rails).to receive(:env) { "staging".inquiry }
    expect {
      worker.perform(5, 5)
    }.to raise_error(
      EmailDormantUsersWorker::DoNotRunOnStagingError
    )
  end

  it "should email dormant users in subselection" do
    dormant_user1 = create(:user, id: 45, current_sign_in_at: 5.days.ago)
    dormant_user2 = create(:user, id: 5, current_sign_in_at: 5.days.ago)

    expect(DormantUserMailerWorker).to receive(:perform_async).with(dormant_user1.id)
    expect(DormantUserMailerWorker).to receive(:perform_async).with(dormant_user2.id)

    worker.perform(5, 5)
  end
end
