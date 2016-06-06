module Echo
  # The Data Management Service is primarily used by providers to manage the usage of
  # the data in their holdings. It may also be used to manage system options that are
  # then available to all providers.
  class DataManagement < Base
    # Retrieve a data quality summary definition used in describing the quality information
    # associated with one or more catalog items.
    def get_data_quality_summary_definition(token, guid)
      builder = Builder::XmlMarkup.new

      builder.ns2(:GetDataQualitySummaryDefinition, 'xmlns:ns2': 'http://echo.nasa.gov/echo/v10', 'xmlns:ns3': 'http://echo.nasa.gov/echo/v10/types', 'xmlns:ns4': 'http://echo.nasa.gov/ingest/v10') do
        builder.ns2(:token, token)
        builder.ns2(:guid, guid)
      end

      payload = wrap_with_envelope(builder)

      make_request(@url, payload)
    end

    # Retrieve all data quality summary definitions (used in describing the quality information
    # associated with one or more catalog items) for a given provider.
    def get_data_quality_summary_definition_name_guids(token, provider_guid)
      builder = Builder::XmlMarkup.new

      builder.ns2(:GetDataQualitySummaryDefinitionNameGuids, 'xmlns:ns2': 'http://echo.nasa.gov/echo/v10', 'xmlns:ns3': 'http://echo.nasa.gov/echo/v10/types', 'xmlns:ns4': 'http://echo.nasa.gov/ingest/v10') do
        builder.ns2(:token, token)
        builder.ns2(:providerGuid, provider_guid)
      end

      payload = wrap_with_envelope(builder)

      make_request(@url, payload)
    end

    # Creates a data quality summary definition for use in describing the quality information
    # associated with one or more catalog items.
    def create_data_quality_summary_definition(token, payload)
      builder = Builder::XmlMarkup.new

      builder.ns2(:CreateDataQualitySummaryDefinition, 'xmlns:ns2': 'http://echo.nasa.gov/echo/v10', 'xmlns:ns3': 'http://echo.nasa.gov/echo/v10/types', 'xmlns:ns4': 'http://echo.nasa.gov/ingest/v10') do
        builder.ns2(:token, token)
        builder.ns2(:dataQualitySummaryDefinition) do
          builder.ns3(:Summary, payload.fetch('Summary')) if payload.key?('Summary')
          builder.ns3(:Name, payload.fetch('Name')) if payload.key?('Name')
          builder.ns3(:OwnerProviderGuid, payload.fetch('OwnerProviderGuid')) if payload.key?('OwnerProviderGuid')
        end
      end

      payload = wrap_with_envelope(builder)

      make_request(@url, payload)
    end

    # Removes a data quality summary definition for use in describing the quality information associated with one or more catalog items.
    def remove_data_quality_summary_definition(token, guids)
      builder = Builder::XmlMarkup.new

      builder.ns2(:RemoveDataQualitySummaryDefinitions, 'xmlns:ns2': 'http://echo.nasa.gov/echo/v10', 'xmlns:ns3': 'http://echo.nasa.gov/echo/v10/types', 'xmlns:ns4': 'http://echo.nasa.gov/ingest/v10') do
        builder.ns2(:token, token)

        builder.ns2(:guids) do
          [*guids].each do |g|
            builder.ns3(:Item, g)
          end
        end
      end

      payload = wrap_with_envelope(builder)

      make_request(@url, payload)
    end

    # Retrieve all data quality summary assignments for a catalog item.
    def get_data_quality_summary_assignments(token, catalog_item_guid)
      builder = Builder::XmlMarkup.new

      builder.ns2(:GetDataQualitySummaryAssignments, 'xmlns:ns2': 'http://echo.nasa.gov/echo/v10', 'xmlns:ns3': 'http://echo.nasa.gov/echo/v10/types', 'xmlns:ns4': 'http://echo.nasa.gov/ingest/v10') do
        builder.ns2(:token, token)
        builder.ns2(:catalogItemGuid, catalog_item_guid)
      end

      payload = wrap_with_envelope(builder)

      make_request(@url, payload)
    end

    # Creates a data quality summary assignment between a catalog item and a data quality summary definition.
    def create_data_quality_summary_assignment(token, provider_guid, definition_guid, catalog_item_guid)
      builder = Builder::XmlMarkup.new

      builder.ns2(:CreateDataQualitySummaryAssignment, 'xmlns:ns2': 'http://echo.nasa.gov/echo/v10', 'xmlns:ns3': 'http://echo.nasa.gov/echo/v10/types', 'xmlns:ns4': 'http://echo.nasa.gov/ingest/v10') do
        builder.ns2(:token, token)
        builder.ns2(:providerGuid, provider_guid)
        builder.ns2(:dataQualitySummaryAssignment) do
          builder.ns3(:DefinitionGuid, definition_guid)
          builder.ns3(:CatalogItemGuid, catalog_item_guid)
        end
      end

      payload = wrap_with_envelope(builder)

      make_request(@url, payload)
    end

    # Removes a data quality summary assignment.
    def remove_data_quality_summary_assignments(token, guids)
      builder.ns2(:RemoveDataQualitySummaryAssignments, 'xmlns:ns2': 'http://echo.nasa.gov/echo/v10', 'xmlns:ns3': 'http://echo.nasa.gov/echo/v10/types', 'xmlns:ns4': 'http://echo.nasa.gov/ingest/v10') do
        builder.ns2(:token, token)

        builder.ns2(:guids) do
          [*guids].each do |g|
            builder.ns3(:Item, g)
          end
        end
      end

      payload = wrap_with_envelope(builder)

      make_request(@url, payload)
    end
  end
end