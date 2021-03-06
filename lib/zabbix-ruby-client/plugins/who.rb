require "zabbix-ruby-client/logger"

module ZabbixRubyClient
  module Plugins
    module Who
      extend self
      extend ZabbixRubyClient::PluginBase

      def collect(*args)
        host = args[0]
        who = get_who
        if $?.to_i != 0
          Log.warn "Are you running on ubuntu ?"
          return []
        end
        back = []
        back << "#{host} who[total] #{time} #{who}"
        return back
      end

      def get_who
        who = `who`
        who.each_line.count
      end

    end
  end
end

ZabbixRubyClient::Plugins.register('who', ZabbixRubyClient::Plugins::Who)

