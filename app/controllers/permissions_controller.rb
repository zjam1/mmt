class PermissionsController < ApplicationController

  skip_before_filter :is_logged_in, only: [:get_all_collections]

  def index
    provider_id = @current_user.provider_id
    response = cmr_client.get_permissions_for_provider(provider_id, token)

    unless response.success?
      Rails.logger.error("Error getting permissions: #{response.inspect}")
      error = Array.wrap(response.body['errors'])[0]
      flash[:error] = error
    end

    @permissions = response.body['items']
    @permissions = construct_permissions_summaries(@permissions)
  end

  def show
    @permission_concept_id = params[:id]
    permission_response = cmr_client.get_permission(@permission_concept_id, token)

    if permission_response.success?
      permission = permission_response.body

      set_catalog_item_identity(permission)

      search_groups_list, search_and_order_groups_list = parse_group_permission_ids(permission['group_permissions'])

      @permission_type = 'Search' unless search_groups_list.blank?
      @permission_type = 'Search & Order' unless search_and_order_groups_list.blank?

      group_retrieval_error_messages = []

      @search_and_order_groups = []
      search_and_order_groups_list.each do |search_and_order_group_id|
        search_and_order_group, error_message = construct_permission_group(search_and_order_group_id)

        @search_and_order_groups << search_and_order_group if search_and_order_group
        group_retrieval_error_messages << error_message if error_message
      end

      @search_groups = []
      search_groups_list.each do |search_group_id|
        search_group, error_message = construct_permission_group(search_group_id)

        @search_groups << search_group if search_group
        group_retrieval_error_messages << error_message if error_message
      end

      flash[:error] = group_retrieval_error_messages.join('; ') if group_retrieval_error_messages.length > 0

    else
      Rails.logger.error("Error retrieving a permission: #{permission_response.inspect}")
      error = Array.wrap(permission_response.body['errors'])[0]
      flash[:error] = error
    end
  end

  def new
    @groups = get_groups_for_permissions
  end


  def create
    hasError = false
    msg = ''
    if params[:permission_name].blank?
      hasError = true
      msg = 'Permission Name is required.'
    elsif params[:collection_options].blank? || params[:collection_options] == 'select'
      hasError = true
      msg = 'Collections must be specified.'
    elsif params[:granule_options].blank? || params[:granule_options] == 'select'
      hasError = true
      msg = 'Granules must be specified.'
    elsif params[:search_groups].nil? && params[:search_and_order_groups].nil?
      hasError = true
      msg = 'Please specify at least one Search group or one Search & Order group.'
    end

    if hasError == true
      Rails.logger.error("Permission Creation Error: #{msg}")
      flash.now[:error] = msg
      @permission_name = params[:permission_name]

      @collection_options = params[:collection_options]
      @collection_selections = params[:collection_selections]
      @granule_options = params[:granule_options]

      @groups = get_groups_for_permissions
      @search_groups = params[:search_groups]
      @search_and_order_groups = params[:search_and_order_groups]

      render :new and return
    end

    request_object = construct_request_object(@current_user.provider_id)
    response = cmr_client.add_group_permissions(request_object, token)

    if response.success?
      flash[:success] = 'Permission was successfully created.'
      Rails.logger.info("#{@current_user.urs_uid} CREATED catalog item ACL for #{@current_user.provider_id}. #{response.body}")

      concept_id = response.body['concept_id']
      redirect_to permission_path(concept_id)
    else
      Rails.logger.error("Permission Creation Error: #{response.inspect}")

      # Look up the error code. If we have a friendly version, use it. Otherwise,
      # just use the error message as it comes back from the CMR.
      friendlyErrorMsg = PermissionsHelper::ErrorCodeMessages[response.status]

      if ! friendlyErrorMsg.blank?
        permission_creation_error = friendlyErrorMsg
      else
        permission_creation_error = Array.wrap(response.body['errors'])[0]
      end

      flash.now[:error] = permission_creation_error

      @permission_name = params[:permission_name]

      @collection_options = params[:collection_options]
      @collection_selections = params[:collection_selections]
      @granule_options = params[:granule_options]

      @groups = get_groups_for_permissions
      @search_groups = params[:search_groups]
      @search_and_order_groups = params[:search_and_order_groups]

      render :new
    end
  end

  def edit
    @permission_concept_id = params[:id]
    permission_response = cmr_client.get_permission(@permission_concept_id, token)

    if permission_response.success?
      permission = permission_response.body

      set_catalog_item_identity(permission)

      @search_groups, @search_and_order_groups = parse_group_permission_ids(permission['group_permissions'])
      @groups = get_groups_for_permissions
    else
      Rails.logger.error("Error retrieving a permission: #{permission_response.inspect}")
      flash[:error] = Array.wrap(permission_response.body['errors'])[0]
      redirect_to permissions_path
    end
  end

  def update
    concept_id = params[:id]
    permission_provider = params[:permission_provider]

    request_object = construct_request_object(permission_provider)
    update_response = cmr_client.update_permission(request_object, concept_id, token)

    if update_response.success?
      flash[:success] = 'Permission was successfully updated.'
      Rails.logger.info("#{@current_user.urs_uid} UPDATED catalog item ACL for #{permission_provider}. #{response.body}")

      redirect_to permission_path(concept_id)
    else
      Rails.logger.error("Permission Update Error: #{update_response.inspect}")
      permission_update_error = Array.wrap(update_response.body['errors'])[0]

      # TODO change to match on 403 response. currently this response from cmr is 400
      if permission_update_error == 'Permission to update ACL is denied'
        flash[:error] = 'You are not authorized to update permissions. Please contact your system administrator.'
        # opt1 send back to show page
        redirect_to permission_path(concept_id)
      else
        flash[:error] = permission_update_error
        # opt2 parse/grab data, render edit with flash message
        @permission_name = params[:permission_name]

        @collection_options = params[:collection_options]
        @collection_selections = params[:collection_selections]
        @granule_options = params[:granule_options]

        @groups = get_groups_for_permissions
        @search_groups = params[:search_groups]
        @search_and_order_groups = params[:search_and_order_groups]

        render :edit
      end
    end
  end

  def get_all_collections
    collections, @errors, hits = get_collections_for_provider(params)

    @option_data = []
    collections.each do |collection|
      opt = [ collection['umm']['entry-title'], collection['umm']['entry-id'] + ' | ' + collection['umm']['entry-title'] ]
      @option_data << opt
    end

    if @errors.length > 0
      render :json => { :success => false }
    else
      respond_to do |format|
        format.json { render json: @option_data }
      end
    end
  end

  private

  def get_collections_for_provider(params)
    # page_size default is 10, max is 2000

    query = { 'provider' => @current_user.provider_id,
              'page_size' => 500 }

    if params.key?('entry_id')
      query['keyword'] = params['entry_id'] + '*'
    end

    if params.key?('page_num')
      query['page_num'] = params['page_num']
    end

    collections_response = cmr_client.get_collections(query, token).body
    parse_get_collections_response(collections_response)
  end

  def get_collections_by_entry_titles(entry_titles)
    # page_size default is 10, max is 2000
    query = { 'page_size' => 100, 'entry_title' => entry_titles }

    collections_response = cmr_client.get_collections(query, token).body
    parse_get_collections_response(collections_response)
  end

  def parse_get_collections_response(response)
    hits = response['hits'].to_i
    errors = response.fetch('errors', [])
    collections = response.fetch('items', [])

    [collections, errors, hits]
  end

  def get_groups
    filters = {}
    filters['provider'] = @current_user.provider_id;
    groups_response = cmr_client.get_cmr_groups(filters, token)
    groups_for_permissions_select = []

    if groups_response.success?
      tmp_groups = groups_response.body['items']
      tmp_groups.each do |group|
        opt = [group['name'], group['concept_id']]
        groups_for_permissions_select << opt
      end
    else
      Rails.logger.error("Get Cmr Groups Error: #{groups_response.inspect}")
      flash[:error] = Array.wrap(groups_response.body['errors'])[0]
      groups_for_permissions_select = nil # what about keeping this as [] instead of nil ?
    end

    groups_for_permissions_select
  end

  def get_groups_for_permissions
    groups_for_permissions_select = get_groups

    # add options for registered users and guest users
    groups_for_permissions_select.unshift(['All Registered Users', 'registered'])
    groups_for_permissions_select.unshift(['All Guest Users', 'guest'])

    groups_for_permissions_select
  end

  def construct_request_object(provider)

    collection_applicable = false
    if params[:collection_options] == 'all-collections' || params[:collection_options] == 'selected-ids-collections'
      collection_applicable = true
    end
    granule_applicable = params[:granule_options] == 'all-granules' ? true : false

    req_obj = {
      'group_permissions' => Array.new,
      'catalog_item_identity' => {
        'name' => params[:permission_name],
        'provider_id' => provider,
        'granule_applicable' => granule_applicable,
        'collection_applicable' => collection_applicable
      }
    }

    if params[:collection_options] == 'selected-ids-collections'
      # The split character below is determined by the Chooser widget configuration. We are using this unusual
      # delimiter becuase collection entry titles could contain commas.
      raw_collection_selections = params[:collection_selections].split('%%__%%')
      entry_titles = []
      raw_collection_selections.each do |collection_selection|
        # collection_selections come from widget as 'entry_id | entry_title',
        # so we need to split them up and pass just entry title values
        parts = collection_selection.split('|')
        entry_titles << parts[1].strip
      end

      req_obj['catalog_item_identity']['collection_identifier'] = {}
      req_obj['catalog_item_identity']['collection_identifier']['entry_titles'] = entry_titles
    end

    search_groups = params[:search_groups] || []
    search_groups.each do |search_group|
      if search_group == 'guest' || search_group == 'registered'
        search_permission = {
          'user_type' => search_group,
          'permissions'=> ['read'] # aka "search"
        }
      else
        search_permission = {
            'group_id'=> search_group,
            'permissions'=> ['read'] # aka "search"
        }
      end

      req_obj['group_permissions'] << search_permission
    end

    search_and_order_groups = params[:search_and_order_groups] || []
    search_and_order_groups.each do |search_and_order_group|
      if search_and_order_group == 'guest' || search_and_order_group == 'registered'
        search_and_order_permission = {
            'user_type' => search_and_order_group,
            'permissions'=> ['read', 'order'] # aka "search"
        }
      else
        search_and_order_permission = {
            'group_id'=> search_and_order_group,
            'permissions'=> ['read', 'order'] # aka "search"
        }
      end

      req_obj['group_permissions'] << search_and_order_permission
    end

    req_obj
  end

  def construct_permissions_summaries(permissions)
    # Search through the permissions of each group and create a summary for display
    permissions.each do |perm|
      permission_summary = {}
      permission_summary_list = []

      group_permissions = perm['acl']['group_permissions']
      group_permissions.each do |group_perm|
        perm_list = group_perm['permissions']
        perm_list.each do |type|
          permission_summary[type] = type
        end
      end

      permission_summary.keys.each do |key|
        key = 'search' if key == 'read'
        permission_summary_list << key.capitalize
      end

      perm['permission_summary'] = permission_summary_list.join ' & '
    end

    permissions
  end

  def parse_group_permission_ids(group_permissions)
    search_groups = []
    search_and_order_groups = []

    group_permissions.each do |group_perm|
      if group_perm['permissions'] == ['read', 'order']
        # add the group id or user type to the list
        search_and_order_groups << (group_perm['group_id'] || group_perm['user_type'])
      elsif group_perm['permissions'] == ['read']
        # add the group id or user type to the list
        search_groups << (group_perm['group_id'] || group_perm['user_type'])
      end
    end

    [search_groups, search_and_order_groups]
  end

  def construct_permission_group(group_id)
    group = {}

    if group_id == 'guest'
      group[:name] = 'All Guest Users'
    elsif group_id == 'registered'
      group[:name] = 'All Registered Users'
    else
      group_response = cmr_client.get_group(group_id, token)
      if group_response.success?
        group = group_response.body
        group[:name] = group['name']
        group[:concept_id] = group_id
        group[:num_members] = group['num_members']
        retrieval_error_message = nil
      else
        retrieval_error_message = Array.wrap(group_response.body['errors'])[0]
        group = nil
      end
    end

    [group, retrieval_error_message]
  end

  def set_catalog_item_identity(permission)
    # parsing for show or edit actions
    show = params[:action] == 'show' ? true : false

    catalog_item_identity = permission['catalog_item_identity']
    @permission_name = catalog_item_identity['name']

    if show
      @collection_options = catalog_item_identity['collection_applicable']
      @granule_options = catalog_item_identity['granule_applicable']
    else
      @collection_options = catalog_item_identity['collection_identifier'] ? 'selected-ids-collections' : 'all-collections'
      @granule_options = catalog_item_identity['granule_applicable'] ? 'all-granules' : 'no-access'
    end

    if catalog_item_identity['collection_identifier']
      entry_titles = catalog_item_identity['collection_identifier']['entry_titles']

      collections, errors, hits = get_collections_by_entry_titles(entry_titles)

      if show
        @collection_entry_ids = []
        collections.each do |collection|
          @collection_entry_ids << collection['umm']['entry-id']
        end
      else
        selected_collections = []
        delimiter = '%%__%%'
        collections.each do |collection|
          # widget needs entry_id | entry_title
          opt = collection['umm']['entry-id'] + ' | ' + collection['umm']['entry-title']
          selected_collections << opt
        end
        # the hidden input can only handle text, so the widget is currently using the delimiter to separate the
        # collection display values
        @collection_selections = selected_collections.join(delimiter)
      end
    end

    @permission_provider = catalog_item_identity['provider_id']
  end
end
