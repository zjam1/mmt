require 'rails_helper'

describe 'Empty Service Draft Related URL Preview' do
  let(:service_draft) { create(:empty_service_draft, user: User.where(urs_uid: 'testuser').first) }

  before do
    login
    visit service_draft_path(service_draft)
  end

  context 'When examing the Related URL section' do
    it 'displays the form title as an edit link' do
      within '#related_url-progress' do
        expect(page).to have_link('Related URL', href: edit_service_draft_path(service_draft, 'related_url'))
      end
    end
  end

  it 'displays the corrent status icon' do
    within '#related_url-progress' do
      within '.status' do
        expect(page).to have_content('Related URL is incomplete')
      end
    end
  end

  it 'displays the correct progress indicators for required fields' do
    within '#related_url-progress .progress-indicators' do
      expect(page).to have_css('.eui-icon.eui-required-o.icon-green.related-url')
    end
  end

  it 'displays the correct progress indicators for non required fields' do
    within '#related_url-progress .progress-indicators' do
      expect(page).to have_css('.eui-icon.eui-fa-circle-o.icon-grey.online-access-url-pattern-match')
      expect(page).to have_css('.eui-icon.eui-fa-circle-o.icon-grey.online-access-url-pattern-substitution')
    end
  end

  it 'displays the stored values correctly within the preview' do
    within '.umm-preview.related_url' do
      expect(page).to have_css('.umm-preview-field-container', count: 1)

      within '#service_draft_draft_related_url_preview' do
        expect(page).to have_css('h5', text: 'Related URL')
        expect(page).to have_link(nil, href: edit_service_draft_path(service_draft, 'related_url', anchor: 'service_draft_draft_related_url'))

        expect(page).to have_css('p', text: 'No value for Related Url provided.')
      end
    end
  end
end