require 'spec_helper'

RSpec.describe RecentCreateWorker do
  subject(:recent_create_worker) { described_class.new }

  let(:classification) { create(:classification) }

  it 'should call create_from_classification' do
    expect(Recent)
      .to receive(:create_from_classification)
      .with(classification)
      .and_call_original
    recent_create_worker.perform(classification.id)
  end

  context 'with existing user recents for this project' do
    before do
      subject_id = classification.subject_ids.last
      recent = Recent.create(classification: classification, subject_id: subject_id)
      recent.update_column(:classification_id, recent.classification_id + 1) # rubocop:disable Rails/SkipsModelValidations
    end

    it 'marks all recents beyond the limit to keep for deletion' do
      allow(Panoptes).to receive(:user_project_recents_limit).and_return(1)
      expect { recent_create_worker.perform(classification.id) }
        .to change {
          Recent.where(
            user_id: classification.user_id,
            project_id: classification.project_id,
            mark_remove: true
          ).count
        }.from(0).to(1)
    end

    it 'does not mark any recents under limit to keep for deletion' do
      expect { recent_create_worker.perform(classification.id) }
        .not_to change {
          Recent.where(
            user_id: classification.user_id,
            project_id: classification.project_id,
            mark_remove: true
          ).count
        }
    end
  end
end
