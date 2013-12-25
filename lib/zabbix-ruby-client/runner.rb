require "zabbix-ruby-client/store"
require "zabbix-ruby-client/data"
require "zabbix-ruby-client/plugins"
require "zabbix-ruby-client/logger"

module ZabbixRubyClient

  class Runner

    def initialize(config, tasks)
      @config = config
      @tasks = tasks

      @store = ZabbixRubyClient::Store.new(
        @config['datadir'],
        @config['zabbix']['host'],
        @config['taskfile'],
        @config['keepdata']
      )

      @data = ZabbixRubyClient::Data.new(@config['host'])
      @logsdir = makedir(@config['logsdir'], 'logs')
      ZabbixRubyClient::Plugins.scan_dirs([ PLUGINDIR ] + @config['plugindirs'])
      ZabbixRubyClient::Log.set_logger(File.join(@logsdir, 'zrc.log'), @config['loglevel'])
      ZabbixRubyClient::Log.debug @config.inspect
    end

    def collect
      @tasks.each do |plugin|
        @data.run_plugin(plugin['name'], plugin['args'])
      end
    end

    def show
      @data.merge.each do |line|
        puts line
      end
    end

    def upload
      file = @store.record(@data.merge)
      command = "#{@config['zabbix']['sender']} -z #{@config['zabbix']['host']} -p #{@config['zabbix']['port']} -T -i #{file}"
      begin
        res = `#{command}`
      rescue Exception => e
        @store.keepdata(file)
        ZabbixRubyClient::Log.debug "Failed ------"
        ZabbixRubyClient::Log.debug command
        ZabbixRubyClient::Log.debug res
        ZabbixRubyClient::Log.debug "-------------"
        ZabbixRubyClient::Log.error "Sending failed."
        ZabbixRubyClient::Log.error e.message
      end
    end

    private

    def makedir(configdir, defaultdir)
      dir = configdir || defaultdir
      FileUtils.mkdir dir unless Dir.exists? dir
      dir
    end

  end
end
