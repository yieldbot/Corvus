#!/usr/bin/env ruby

require 'sensu-handler'
require 'redphone/pagerduty'

class Pagerduty < Sensu::Handler

  def acquire_setting(name)
    product = ARGV[0]
    settings[product][name]
  end

  # Create an incident key
  #
  #
  def incident_key
    @event['client']['name'] + '/' + @event['check']['name']
  end

   pagerduty"
  # @return [integer] exit code
  def handle
    description = @event['check']['notification']
    description ||= [@event['client']['name'], @event['check']['name'], @event['check']['output']].join(' : ')
    begin
      timeout(10) do
        response = case @event['action']
                   when 'create'
                     Redphone::Pagerduty.trigger_incident(
                       service_key: acquire_setting('api_key'),
                       incident_key: incident_key,
                       description: description,
                       details: @event
                     )
                   when 'resolve'
                     Redphone::Pagerduty.resolve_incident(
                       service_key: acquire_setting('api_key'),
                       incident_key: incident_key
                     )
        end
        if response['status'] == 'success'
          puts 'pagerduty -- ' + @event['action'].capitalize + 'd incident -- ' + incident_key
        else
          puts 'pagerduty -- failed to ' + @event['action'] + ' incident -- ' + incident_key
        end
      end
    rescue Timeout::Error
      puts 'pagerduty -- timed out while attempting to ' + @event['action'] + ' a incident -- ' + incident_key
    end
  end
end
