Zabbix Ruby Client
====================

[![Gem Version](https://badge.fury.io/rb/zabbix-ruby-client.png)](http://rubygems.org/gems/zabbix-ruby-client)
[![Build Status](https://travis-ci.org/eduvo/zabbix-ruby-client.png?branch=master)](https://travis-ci.org/eduvo/zabbix-ruby-client)
[![Coverage Status](https://coveralls.io/repos/eduvo/zabbix-ruby-client/badge.png)](https://coveralls.io/r/eduvo/zabbix-ruby-client)
[![Dependency Status](https://gemnasium.com/eduvo/zabbix-ruby-client.png)](https://gemnasium.com/eduvo/zabbix-ruby-client)
[![Code Climate](https://codeclimate.com/github/eduvo/zabbix-ruby-client.png)](https://codeclimate.com/github/eduvo/zabbix-ruby-client)

----

This tool is designed to make easy to install zabbix reporter on monitored servers using zabbix-sender rather than zabbix-agent. It targets on monitoring mainly linux servers and is built on a plugin system so that you can decide what is going to be reported.

The development is still in progress but it produces results and works in my case. Use at your own risk and read the code first. It is developed under ruby 2 but should work on 1.9.3 as well.

Check the [Changelog](CHANGELOG.md) for recent changes, code is still under huge development and is likely to move a lot until version 0.1.

## Why ?

Yes why use zabbix ruby client with zabbix-sender rather than zabbix-agent ?

There are various reasons for that. But the purpose of this tool ultimately is to fulfill the functions of the zabbix-sender, reducing the requirement of installation to only the zabbix ruby client.

There are compromises that make this use of the sender with zabbix ruby client pertinent:

* you prefer to rely on a cronjob rather than on a daemon for data collection
* you don't mind having a minimum time between data collection of 1 minute (cron don't handle seconds)
* you want to specify your discovery at client level rather than at server level. When I first used auto discovery for interfaces or file systems, it was discovering such a huge number of things with such a wide inconsistency of naming that it was pretty hard to think about a regexp to limit what was pertinent or not. Sometimes a discovery rule would need to have a regexp per host, which zabbix don't permit, or it gets very complicated. In a very diverse context, declarative discovery is much simpler.
* you already have ruby installed on all your servers (which is the case if you use chef or puppet)

The objectives for version 0.1 of zabbix ruby client are to be able to handle dropping connection by buffering the data collection and send all what was not sent the next time it's possible. So there should be no real difference on that feature with the agent.

At some point all zabbix ruby client plugins will be usable by the agent as well, actually, so it should not make any difference. But the initial setup I have in my infrastructure led me to chose the sender rather than the agent. But that will be later on when the code will get better abstraction. For now I just want it to work and collect my data. Which it does. The full compatibility for use by the agent would probably be a target for version 0.2.

## Installation

Install it yourself as:

    gem install zabbix-ruby-client

## Usage

    zrc init [name]
    # will create a directory [name] (default: zabbix-ruby-client) for
    # storing configuration and temporary files

    cd [name]
    bundle
    # makes the zabbix-ruby-client [name] ready to run
    # then edit config.yml according to your needs

    bundle exec zrc
    # to list available commands

    bundle exec zrc show
    # to test the data collection

## Setting up cronjobs

When ready just install a cron task according to your environment

    echo '* * * * * /bin/bash -lc "cd /path/to/zrc && bundle exec zrc upload"' | crontab
    # or
    echo '* * * * * /bin/zsh -c ". $HOME/.rvm/scripts/rvm && cd /path/to/zrc && bundle exec zrc upload"' | crontab
    # or
    echo '* * * * * /bin/zsh -c "export RBENV_ROOT=/usr/local/var/rbenv && eval \"$(rbenv init - zsh)\" && cd /path/to/zrc && bundle exec zrc upload"' | crontab

By default `zrc show` and `zrc upload` will read config.yml (for the general config) and minutely.yml (for the list of plugins to run).

You can use -c to specify another config file, and -t to use another list of plugins. The `zrc init` command will create sample minutely.yml, hourly.yml and monthly.yml but you can create any arbitrary list of plugins, that can be used in your cronjobs.

Here is an example setup using the files generated by the init:

    * * * * * /bin/zsh -c ". $HOME/.rvm/scripts/rvm && cd $HOME/zrc && bundle exec zrc upload"
    0 * * * * /bin/zsh -c ". $HOME/.rvm/scripts/rvm && cd $HOME/zrc && bundle exec zrc upload -t hourly.yml"
    0 0 1 * * /bin/zsh -c ". $HOME/.rvm/scripts/rvm && cd $HOME/zrc && bundle exec zrc upload -t monthly.yml"

## Plugins

There are a set of standart plugins included in the package, aimed at linux systems.

* **ubuntu** system stats ([system_tpl](master/zabbix-templates/system_tpl.xml) includes the following)
  * **load** (uses /proc/loadavg) [load_tpl](master/zabbix-templates/load_tpl.xml)
  * **cpu** (uses /proc/stat) [cpu_tpl](master/zabbix-templates/cpu_tpl.xml)
  * **memory** (uses /proc/meminfo) [memory_tpl](master/zabbix-templates/memory_tpl.xml)
  * **disk** (uses /proc/diskstats) [disk_tpl](master/zabbix-templates/disk_tpl.xml)
    * args [ "md-0", "/", "vgebs" ] = group identifier, mountpoint, groupname where identifier is what is found in /proc/diskstats, and groupname is something found in df command. The mount point will be used as label.
  * **network** (uses /proc/net/dev) [network_tpl](master/zabbix-templates/network_tpl.xml)
    * args [ eth0 ] is just the interface identifier
  * **apt** (uses ubuntu /usr/lib/update-notifier/apt-check) this one will populate the 'tag' field in host info, and is supposed to run every few hours or at least not every minute [apt_tpl](master/zabbix-templates/apt_tpl.xml)
  * **sysinfo** (uses uname -a) is populating the host info in the inventory, and should be ran at setup and/or monthly [sysinfo_tpl](master/zabbix-templates/sysinfo_tpl.xml)
* **apache** (depends on mod_status with status_extended on) [apache_tpl](master/zabbix-templates/apache_tpl.xml)
* **mysql** (uses mysqladmin extended-status) [mysql_tpl](master/zabbix-templates/mysql_tpl.xml)
* **postgres** (uses psql and pg_stat_database) [postgres_tpl](master/zabbix-templates/postgres_tpl.xml)
  * best is to use a .pgpass file see http://www.postgresql.org/docs/9.0/interactive/libpq-pgpass.html
* **nginx** (requires httpStubStatus nginx module) [nginx_tpl](master/zabbix-templates/nginx_tpl.xml)
* **redis** (uses redis-cli info) [redis_tpl](master/zabbix-templates/redis_tpl.xml)
  * args [ "/path/to/redis-cli", "options to connect" ]
* **openvpn** (uses /etc/openvpn/openvpn-status.log) [openvpn_tpl](master/zabbix-templates/openvpn_tpl.xml)
  * args [ "/etc/openvpn/openvpn-status.log" ]
* **cisco** (type ASA 5510) [cisco_tpl](master/zabbix-templates/cisco_tpl.xml)
  * uses a snmp setup
* **RabbitMQ** (uses [rabbitmqadmin](http://www.rabbitmq.com/management-cli.html)) [rabbitmq_tpl](master/zabbix-templates/rabbitmq_tpl.xml)
  * args [ "/path/to/rabbitmqadmin", "login", "password" ]
* **mysqlcommand** (uses arbitrary mysql commands to create custom items)
  * args [ "app_name", "dbname", "command_args", "command1_name", "command1_sql", "command2_name", "command2_sql" ]
  * the 3 first args are common to all commands
    * item_name will create an item named `app.app_name[command1_name]`
  * past the 3 first args, the rest are key-values with a name and a sql command.
    * if the name begins with a `_`, this underscore will be removed and the sql command is expected to be a list of value grouped by labels. For example [ "_usertypes", "select type, count(*) from users group by type" ] will generate something like
    ````
    myhost app.app_name[usertypes,APIUser] 1407593152 10
    myhost app.app_name[usertypes,User] 1407593152 2843
    ...
    ````
    * if the name includes commas (`,`) the sql command is expected to return one row with multple value. For example [ "max_attempts,min_attempts", "select max(attempts), min(attempts) from delayed_jobs"] will generate
    ````
    myhost app.app_name[max_attempts] 1407593152 40
    myhost app.app_name[min_attempts] 1407593152 5
    ````
  * in all other case (no starting `_` and no `,`) in the item name, the sql command is expected to return a single columns and a single row, typically for `count(*)` commands.


You can add extra plugins in a plugins/ dir in the working dir, just by copying one of the existing plugins in the repo and change to your need. All plugins present in plugins/ will be loaded if present in the config file you use. That can be convenient to test by using the -t flag, for example `bundle exec zrc -t testplugin.yml` where testplugin.yml only contains the name and args for your plugin.

## Custom plugins how-to

With the default config there is a plugins/ dir specified where you can put your own custom plugins. Those plugins need at least one `collect(*args)` method and optionaly a `discover(*args)` if this plugins plays the discover role.

Here is a basic plugin skeleton you can reproduce:

```ruby
class ZabbixRubyClient
  module Plugins
    module Myplugin
      extend self

      def collect(*args)
        host = args[0]
        # the rest of args are the params you pass in the args: in your yml config file
        string = args[1]
        int = args[2]

        time = Time.now.to_i
        back = []
        back << "#{host} myplugin[item] #{time} #{string} #{int}"
        return back
      end

    end
  end
end

ZabbixRubyClient::Plugins.register('myplugin', ZabbixRubyClient::Plugins::Myplugin)
```

You can test custom plugins by creating a new `myplugin.yml` file with:

```yaml
---
- name: myplugin
  args: [ "something", 42 ]
```

and then use the `show` command to try it out and see what will be sent to the server, and use `upload` for testing the template you made for it on the zabbix configuration panel:

```
$ bundle exec zrc show -t myplugin.yml
myhost myplugin[item] 1381669455 something 42
```

## What is server or network goes down ?

The zabbix ruby client has a pending system, that keeps the data if it was not sent, for sending it in the next iteration. Data is kept at each iteration until it's delivered (experimental feature).

## Note about security

*note: I switched to usage of OpenVPN for communication between all my servers, which is much better than ssh tunnels, but this setup described below still is useful*

As you may already know, Zabbix is not very concerned about securing exchanges between agent and server, or sender and server. A cautious sysadmin will then properly manage his setup using ssh tunneling.

After launching manual tunnels and ensuring their survival with monit I tried `autossh` which is much more reliable. It requires to have keys exchanged from server and client, in my case I prefer doing reverse tunnels from server, because I have some plan about doing a resend from client in case server didn't open the tunnel (in case of server reboot or network failure). That resend trick is not implemented yet though.

I first created on both sides an autossh user with no console and no password:

```
sudo useradd -m -r -s /bin/false -d /usr/local/zabtunnel zabtunnel
```

On the zabbix server I created a key that I transfered to the clients in `/usr/local/zabtunnel/.ssh/authorized_keys`

```
sudo su -s /bin/bash - zabtunnel
ssh-keygen
```

Then I copy `id_rsa.pub` over to `/usr/local/zabtunnel/.ssh/authorized_keys` on each client.

Check [autossh doc](http://www.harding.motd.ca/autossh/README), note that ubuntu has a package for it. Here is what my `/usr/local/bin/autossh.sh` looks like:

```bash
#!/bin/sh

HOSTLIST="host1 host2 host3 etc"

for i in $HOSTLIST; do
  sudo -u zabtunnel \
    AUTOSSH_LOGLEVEL=6 \
    AUTOSSH_LOGFILE=/usr/local/zabtunnel/$i.log \
    AUTOSSH_PIDFILE=/usr/local/zabtunnel/$i.pid \
    /usr/bin/autossh -2 -M 0 -f -qN \
      -o 'ServerAliveInterval 60' \
      -o 'ServerAliveCountMax 3' \
      -R 10051:localhost:10051 $i
done

exit 0
```

Then you can change zabbix-server config and add a localhost ListenIP (by default it listens to all interfaces)

```
ListenIP 127.0.0.1
```

## Todo

* improve templates for graphs
* add more plugins
  * memcache
  * mysql master/slave
  * postgres replication
  * monit
  * passenger
  * logged users
  * denyhosts
  * postfix
  * sendgrid
  * airbrake
* try to work out a way to create host/graphs/alerts from the client using Zabbix API

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

* [@mose](https://github.com/mose) - author

## License

Copyright 2013 [Faria Systems](http://faria.co) - MIT license - created by mose at mose.com
