#!/usr/bin/env ruby

require 'sensu-handler'
require 'redphone/pagerduty'

class Pagerduty < Sensu::Handler
  # Acquires the mail settings from a json file dropped via Chef
  #
  # These settings will set who the mail should be set to along with any
  # necessary snmtp settings.  All can be overridden in the local Vagrantfile
  #
  # @example Get a setting
  #   "acquire_setting('alert_prefix')" #=> "go away"
  # @param name [string] the alert heading
  # @return [string] the configuration string
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

  # Create the pagerduty alert and ship it
  # @example Set the notification type to CRITICAL
  #   "handle" #=> "A well-formed call to pagerduty"
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
