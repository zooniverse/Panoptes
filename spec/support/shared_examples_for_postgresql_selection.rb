shared_examples "select for incomplete_project" do
  let(:args) { opts }
  let(:selector) { Subjects::PostgresqlSelection.new(workflow, user, args) }
  let(:unseen_count) do
    sms_count - seen_count
  end

  def run_limit_selection(limit)
    selector = Subjects::PostgresqlSelection.new(
      workflow, user, (args || {}).merge(limit: limit)
    )
    selector.select
  end

  context "when a user has only seen a few subjects" do
    let(:seen_count) { 5 }
    let(:limit) { nil }
    let(:args) { opts.merge(limit: limit) }
    let(:uss) do
      subject_ids = sms_scope.sample(seen_count).map(&:subject_id)
      create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
    end

    context "with a limit of 1" do
      let(:limit) { 1 }

      it 'should return an unseen subject' do
        seen_ids = uss.subject_ids
        selected = selector.select.first
        expect(seen_ids).to_not include(selected)
      end
    end

    context "with a limit of 10" do
      let(:limit) { 10 }

      it 'should not have duplicates' do
        result = selector.select
        expect(result).to match_array(result.to_a.uniq)
      end
    end

    # Account for the loop cut off limit constructing the random sample
    it 'should always return an approximate sample of subjects up to the unseen limit' do
      (1..unseen_count).each do |limit|
        results_size = run_limit_selection(limit).length
        expect(results_size).to eq(limit)
      end
    end
  end

  context "when a user has seen most of the subjects" do
    let(:seen_count) { 20 }
    let!(:uss) do
      subject_ids = sms_scope.sample(seen_count).map(&:subject_id)
      create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
    end

    it 'should return as many subjects as possible' do
      (1..unseen_count).each do |limit|
        results_size = run_limit_selection(limit).length
        expect(results_size).to eq(limit)
      end
    end
  end
end
