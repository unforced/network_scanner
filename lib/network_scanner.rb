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
    # Prevents the user from having to deal with namespacing. This is probably hacky
    def new(*args)
      Scanner.new(*args)
    end
  end

  class Scanner
    attr_accessor :pool_size, :format, :output_name

    def initialize(opts = {})
      @pool_size = 100
      @format = 'text'
    end
    
    def text?
      @format == 'text'
    end

    def json?
      @format == 'json'
    end

    def get_interface_ips(interface)
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
      
      @ips_to_check = []

      first_range.each do |first|
        second_range.each do |second|
          third_range.each do |third|
            fourth_range.each do |fourth|
              @ips_to_check << "#{first}.#{second}.#{third}.#{fourth}"
            end
          end
        end
      end

      puts "Checking ips in (#{first_range}).(#{second_range}).(#{third_range}).(#{fourth_range})"
      return @ips_to_check
    end

    def get_range_ips(range)
      start, finish = range.split('-', 2).map{|ip| ip.split('.')}
      first_range = start[0]..finish[0]
      second_range = start[1]..finish[1]
      third_range = start[2]..finish[2]
      fourth_range = start[3]..finish[3]

      @ips_to_check = []

      first_range.each do |first|
        second_range.each do |second|
          third_range.each do |third|
            fourth_range.each do |fourth|
              @ips_to_check << "#{first}.#{second}.#{third}.#{fourth}"
            end
          end
        end
      end

      puts "Checking ips in (#{first_range}).(#{second_range}).(#{third_range}).(#{fourth_range})"
      return @ips_to_check
    end

    def get_cache_ips(file)
      @ips_to_check = []

      if text?
        File.open(file).each_line do |ip|
          @ips_to_check << ip
        end
      elsif json?
        JSON.parse(File.read(file)).each do |ip|
          @ips_to_check << ip
        end
      end
      return @ips_to_check
    end

    def check_pings
      raise Exception.new("Must specify ips to check(interface/range/cache)") unless @ips_to_check

      @ips = []

      pool = Thread.pool(@pool_size)

      if self.output_name
        out = File.open(self.output_name, 'w')
      else
        out = STDOUT
      end

      @ips_to_check.each do |ip|
        pool.process do
          # For some reason &> isn't working, so pipe stdout and then stderr
          if system("ping -c 1 #{ip} >> /dev/null 2> /dev/null")
            @ips << ip
            if text?
              out.print "#{ip}\n"
            end
          end
        end
      end

      pool.shutdown

      if json?
        out.puts(JSON.pretty_generate(@ips))
      end

      out.close unless out == STDOUT

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
      raise Exception.new("Must scan ips first (Specify an interface or cacheread)") unless @ips_to_check

      puts "Checking for ports out of a total of #{@ips_to_check.length} ips"

      if self.output_name
        out = File.open(self.output_name, 'w')
      else
        out = STDOUT
      end

      pool = Thread.pool(@pool_size)

      @ips = []

      @ips_to_check.each do |ip|
        pool.process do
          if port_open?(ip, port)
            @ips << ip
            if text?
              out.print "#{ip}\n"
            end
          end
        end
      end

      pool.shutdown

      if json?
        out.puts(JSON.pretty_generate(@ips))
      end

      out.close unless out == STDOUT

      return @ips
    end
  end
end
