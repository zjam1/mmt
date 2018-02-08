require 'rails_helper'

describe 'Related URL Form', reset_provider: true, js: true do
  before do
    login
    draft = create(:empty_service_draft, user: User.where(urs_uid: 'testuser').first)
    visit edit_service_draft_path(draft, 'related_url')
  end

  context 'when submitting the form' do
    before do
      fill_in 'Description', with: 'Test related url'
      select 'Distribution URL', from: 'Url Content Type'
      select 'Get Service', from: 'Type'
      select 'Software Package', from: 'Subtype'
      fill_in 'Url', with: 'nasa.gov'
      select 'application/json', from: 'Mime Type'
      select 'HTTP', from: 'Protocol'
      fill_in 'Full Name', with: 'Test Service'
      fill_in 'Data ID', with: 'Test data'
      fill_in 'Data Type', with: 'Test data type'
      fill_in 'service_draft_draft_related_url_get_service_uri_0', with: 'Test URI 1'
      click_on 'Add another Uri'
      fill_in 'service_draft_draft_related_url_get_service_uri_1', with: 'Test URI 2'

      within '.nav-top' do
        click_on 'Save'
      end

      # TODO validation isn't working correctly
      click_on 'Yes'
    end

    it 'displays a confirmation message' do
      expect(page).to have_content('Service Draft Updated Successfully!')
    end

    it 'populates the form with the values' do
      expect(page).to have_field('service_draft_draft_related_url_description', with: 'Test related url')
      expect(page).to have_field('service_draft_draft_related_url_url_content_type', with: 'DistributionURL')
      expect(page).to have_field('service_draft_draft_related_url_type', with: 'GET SERVICE')
      expect(page).to have_field('service_draft_draft_related_url_subtype', with: 'SOFTWARE PACKAGE')
      expect(page).to have_field('service_draft_draft_related_url_url', with: 'nasa.gov')
      expect(page).to have_field('service_draft_draft_related_url_get_service_mime_type', with: 'application/json')
      expect(page).to have_field('service_draft_draft_related_url_get_service_protocol', with: 'HTTP')
      expect(page).to have_field('service_draft_draft_related_url_get_service_full_name', with: 'Test Service')
      expect(page).to have_field('service_draft_draft_related_url_get_service_data_id', with: 'Test data')
      expect(page).to have_field('service_draft_draft_related_url_get_service_data_type', with: 'Test data type')
      expect(page).to have_field('service_draft_draft_related_url_get_service_uri_0', with: 'Test URI 1')
      expect(page).to have_field('service_draft_draft_related_url_get_service_uri_1', with: 'Test URI 2')
    end
  end
end
