require 'test/unit'
require 'test_helper'
require 'lib/fluent/plugin/in_network_probe.rb'
require 'pp'


class NetworkProbeCurlInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    probe_type curl
    target google.co.jp
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::NetworkProbeInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'curl',          d.instance.probe_type
    assert_equal 'google.co.jp',      d.instance.target
  end

  def test_curl
    d = create_driver

    pp d.instance.exec_curl
  end


  def test_get_events
    d = create_driver

    # d.instance.before_events = before_events_stub
  end

  def test_get_usage
    d = create_driver

    # d.instance.get_usages
  end

end



