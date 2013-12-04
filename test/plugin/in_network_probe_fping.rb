require 'test/unit'
require 'test_helper'
require 'lib/fluent/plugin/in_network_probe.rb'
require 'pp'


class NetworkProbeFpingInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    probe_type fping
    target localhost
  ]


  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::NetworkProbeInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'localhost',      d.instance.target
    assert_equal 'fping',          d.instance.probe_type
  end

  def test_fping
    d = create_driver

    d.instance.exec_fping
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






