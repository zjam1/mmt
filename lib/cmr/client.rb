module Cmr
  class Client
    def self.client_for_environment(env, service_configs)
      service_config = service_configs['earthdata'][env]
      urs_client_id = service_configs['urs'][Rails.env.to_s][service_config['urs_root']]
      Cmr::Client.new(service_config, urs_client_id)
    end

    def initialize(service_config, urs_client_id)
      @config = service_config
      clients = []
      clients << CmrClient.new(@config['cmr_root'], urs_client_id)
      clients << EchoClient.new(@config['echo_root'], urs_client_id)
      clients << UrsClient.new(@config['urs_root'], urs_client_id)
      launchpad_root = 'launchpad_sbx_root'
      launchpad_root = 'launchpad_root' if ENV['launchpad_prod'] == 'true'
      clients << LaunchpadClient.new(@config[launchpad_root], urs_client_id)
      @clients = clients
    end

    def method_missing(method_name, *arguments, &block)
      client = @clients.find {|c| c.respond_to?(method_name)}
      if client
        client.send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to?(method_name, include_private = false)
      @clients.any? {|c| c.respond_to?(method_name, include_private)} || super
    end
  end
end
