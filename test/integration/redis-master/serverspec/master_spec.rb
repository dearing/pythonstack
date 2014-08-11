# encoding: UTF-8

require_relative 'spec_helper'

describe service('redis6379-master') do
  it { should be_enabled }
end

case os[:family]
when 'Ubuntu'
  describe process('redis-server') do
    # must use process here as serverspec expects init scripts to return stdout
    # "running" and falls back to a bad 'ps aux'
    it { should be_running }
  end
else
  describe service('redis6379-master') do
    it { should be_running }
  end
end

describe port(6379) do
  it { should be_listening }
end

redis_query = 'redis-cli -p 6379 INFO'
describe command(redis_query) do
  it { should return_stdout(/^# Server/) }
  it { should return_stdout(/^uptime_in_seconds:/) }
  it { should return_stdout(/^role:master/) }
end

describe file('/etc/redis') do
  it { should be_directory }
end

describe file('/etc/redis/6379-master.conf') do
  it { should contain('port 6379') }
end
