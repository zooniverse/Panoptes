shared_examples "an email dump exporter" do
  RSpec::Matchers.define :a_formatted_user_email do |x|
    match do |csv_row|
      csv_row.is_a?(Array) &&
      csv_row.length == 1
      csv_row.first.match(/.+@.+/)
    end
  end

  let(:inactive_user) { create(:user, activated_state: :inactive) }
  let(:invalid_email_user) { create(:user, valid_email: false) }

  before do
    users
    inactive_user
    invalid_email_user
  end

  after do
    worker.perform(export_params)
  end

  it "should create a csv file with the correct number of entries" do
    expect_any_instance_of(CSV)
      .to receive(:<<)
      .with(a_formatted_user_email)
      .exactly(users.length)
      .times
  end

  it 'calls the dump processor' do
    processor = double
    expect(CsvDumps::DumpProcessor).to receive(:new)
                                         .with(an_instance_of(Formatter::Csv::UserEmail),
                                               an_instance_of(scope_class),
                                               an_instance_of(CsvDumps::DirectToObjectStorage)).and_return(processor)
    expect(processor).to receive(:execute).once
  end
end
