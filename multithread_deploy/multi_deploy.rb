#!/usr/bin/ruby
require 'thread'
require 'logger'
require 'net/scp'
#require 'net/ping'

def func(host)
  log = Logger.new("#{host}.log")
  log.info("pinging #{host}...")
  if ENV['OS'].eql?("Windows_NT")
    ping_result = `ping -n 1 #{host}`
    if ping_result.include?("Request timed out") || ping_result.include?("host unreachable")
      log.error "ping failed. exiting..."
      return
    else
      log.info "ping successful."
    end
  else
    ping_result = `ping -c 1 #{host}`
    if $?.exitstatus != 0
      log.error "ping failed. exiting..."
      return
    else
      log.info "ping successful."
    end
  end
  begin
    Net::SCP.start(host, "root", :password => "password") do |scp|
      scp.upload! "/source/file/path", "/destination/file/path"
    end
  rescue Timeout::Error => e
     log.error("Timed out. #{e}")
  rescue Errno::EHOSTUNREACH => e
    log.error("Host unreachable. #{e}")
  rescue Errno::ECONNREFUSED => e
      log.error("Connection refused. #{e}")
  rescue Net::SSH::AuthenticationFailed => e
      log.error("Authentication failure. #{e}")
  end
end

#main
max_concurrent_threads = 10
hosts_file = File.open("hosts.txt","r")
hosts_file.each_line do |line|
  thr = Thread.new do
    func(line.chomp)
  end
  #wait until total threads goes below maximum allowed threads
  sleep 1 while Thread.list.size > max_concurrent_threads
end
#wait for the rest of the threads to finish
sleep 1 while Thread.list.size > 1
hosts_file.close