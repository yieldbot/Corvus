#!/usr/bin/env ruby

require 'sensu-handler'
require 'redphone/pagerduty'

class Pagerduty < Sensu::Handler
  def acquire_setting(name)
    product = ARGV[0]
    settings[product][name]
  end

  def acquire_monitored_instance
    @event['client']['name']
  end

  # Create an incident key
  #
  #
  def incident_key
    acquire_monitored_instance + '/' + @event['check']['name']
  end

  def check_data
    @event
  end

  def clean_output
    @event['check']['output'].partition(':')[0]
  end

  # Create the pagerduty alert and ship it
  # @example Set the notification type to CRITICAL
  #   "handle" #=> "A well-formed call to pagerduty"
  # @return [integer] exit code
  def handle
    description ||= [acquire_monitored_instance, @event['check']['name'], clean_output].join(' : ')
    begin
      timeout(10) do
        response = case @event['action']
                   when 'create'
                     Redphone::Pagerduty.trigger_incident(
                       service_key: acquire_setting('api_key'),
                       incident_key: incident_key,
                       description: description,
                       details: check_data
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
