# Preview emails at http://localhost:3000/rails/mailers/draft_mailer
class DraftMailerPreview < ActionMailer::Preview
  def new_draft_published_notification
    user = { name: 'Captain Planet', email: 'supergreen@bluemarble.com' }
    concept_id = 'C1200000007-SEDAC'
    revision_id = 1
    short_name = 'CIESIN_SEDAC_EPI_2010'
    version = 2010

    DraftMailer.draft_published_notification(user, concept_id, revision_id, short_name, version)
  end

  def record_updated_notification
    user = { name: 'Captain Planet', email: 'supergreen@bluemarble.com' }
    concept_id = 'C1200000059-LARC'
    revision_id = 3
    short_name = 'AE_5DSno'
    version = 1

    DraftMailer.draft_published_notification(user, concept_id, revision_id, short_name, version)
  end
end
