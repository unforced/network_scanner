require "network_scanner/version"
require 'json'
require 'socket'
require 'timeout'
require 'thread/pool'
require 'thread'

module Enumerable
  def index_by
    if block_given?
      Hash[map { |elem| [yield(elem), elem] }]
    else
      to_enum :index_by
    end
  end
end

module NetworkScanner
  class << self
    # Avoids the user having to deal with namespacing. This is probably hacky
    def new(*args)
      Scanner.new(*args)
    end
  end

  class Scanner
    attr_accessor :pool_size

    def initialize(opts = {})
      @pool_size = 100
    end

    def get_ips(interface)
      ifconfig = `ifconfig`.split("\n\n").index_by{|x| x[/\w+/,0]}
      inet = ifconfig[interface][/inet addr:([^\s]*)/, 1].split('.')
      broadcast = ifconfig[interface][/Bcast:([^\s]*)/, 1].split('.')
      mask = ifconfig[interface][/Mask:([^\s]*)/, 1].split('.')

      start_first = inet[0].to_i & mask[0].to_i
      start_second = inet[1].to_i & mask[1].to_i
      start_third = inet[2].to_i & mask[2].to_i
      start_fourth = inet[3].to_i & mask[3].to_i

      first_range = start_first..broadcast[0].to_i
      second_range = start_second..broadcast[1].to_i
      third_range = start_third..broadcast[2].to_i
      fourth_range = start_fourth..broadcast[3].to_i

      @ips = []

      pool = Thread.pool(@pool_size)

      ips_to_check = []

      first_range.each do |first|
        second_range.each do |second|
          third_range.each do |third|
            fourth_range.each do |fourth|
              ips_to_check << "#{first}.#{second}.#{third}.#{fourth}"
            end
          end
        end
      end

      puts "Checking for ips in (#{first_range}).(#{second_range}).(#{third_range}).(#{fourth_range})"
      ips_to_check.each do |ip|
        pool.process do
          @ips << ip if system("ping -c 1 #{ip} >> /dev/null")
        end
      end

      pool.shutdown

      return @ips
    end

    def port_open?(ip, port)
      Timeout::timeout(0.5) do
        s = TCPSocket.new(ip,port)
        s.close
        return true
      end
    rescue Timeout::Error
      return false
    end

    def check_ports(port)
      queue = Queue.new

      puts "Checking for ports out of a total of #{@ips.length} ips"

      @ips.each do |ip|
        queue << ip
      end

      pool = Thread.pool(200)

      until(queue.empty?)
        pool.process do
          unless queue.empty?
            ip = queue.pop
            puts ip if port_open?(ip, port)
          end
        end
      end

      pool.shutdown unless pool.done?
    end

    def cache(file)
      if !@ips
        raise Exception.new("Must scan ips before caching (Specify an interface)")
      end
      File.open(file, 'w'){|f| f.puts(JSON.pretty_generate(@ips))}
    end

    def cacheread(file)
      @ips = JSON.parse(File.read(file))
    end
  end
end
