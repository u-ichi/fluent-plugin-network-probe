module Fluent
  class NetworkProbeInput < Input
    Fluent::Plugin.register_input("network_probe", self)

    config_param :probe_type
    config_param :target

    config_param :interval,          :default => 60               # sec

    config_param :fping_count,       :default => 5                # number
    config_param :fping_timeout,     :default => 2                # sec
    config_param :fping_interval,    :default => 1                # sec
    config_param :fping_exec,        :default => '/usr/bin/fping'

    config_param :curl_protocol,     :default => 'http'           # http or https
    config_param :curl_port,         :default => 80               # number
    config_param :curl_path,         :default => '/'              # path
    config_param :curl_count,        :default => 5                # number
    config_param :curl_timeout,      :default => 2                # sec
    config_param :curl_interval,     :default => 1                # sec
    config_param :curl_exec,         :default => '/usr/bin/curl'

    config_param :tag,               :default => "network_probe"
    config_param :debug_mode,        :default => false

    def initialize
      require "eventmachine"

      super
    end

    def configure(conf)
      super

      @conf = conf
    end

    def start
      super
      @thread = Thread.new(&method(:run))
      $log.info "starting network probe, target #{@target} probe_type #{@probe_type}."
    end

    def shutdown
      super
      @thread.kill
    end

    def run
      init_eventmachine
      EM.run do
        EM.add_periodic_timer(@interval) do
          begin
            EM.defer do
              Engine.emit("#{@tag}_#{@target}", Engine.now, exec_fping) if @probe_type == 'fping'
            end
            EM.defer do
              Engine.emit("#{@tag}_#{@target}", Engine.now, exec_curl) if @probe_type == 'curl'
            end
          rescue => ex
            $log.warn("EM.periodic_timer loop error.")
            $log.warn("#{ex}, tracelog : \n#{ex.backtrace.join("\n")}")
          end
        end
      end
    end

    def exec_fping
      cmd = "#{@fping_exec} -i #{@fping_interval*1000} -T #{@fping_timeout} -c #{@fping_count} #{@target} -s"

      cmd_results = run_cmd(cmd)

      round_trip_times = Hash.new(nil)

      cmd_results[1].split("\n").each do |line|
        if /([^\s]*) ms \(min round trip time\)/=~ line
           round_trip_times[:min] = $1.to_f
        end
        if /([^\s]*) ms \(avg round trip time\)/=~ line
           round_trip_times[:avg]= $1.to_f
        end
        if /([^\s]*) ms \(max round trip time\)/=~ line
           round_trip_times[:max] = $1.to_f
        end
      end

      round_trip_times
    end


    def exec_curl
      cmd = "#{@curl_exec} #{@curl_protocol}://#{@target}:#{@curl_port}#{@curl_path} -w \\\n\%\{time_total\} -m #{@curl_timeout}"

      result_times = []

      @curl_count.times do
        cmd_results = run_cmd(cmd)
        result_times << cmd_results[0].split("\n").last.to_f * 1000
        sleep @curl_interval
      end

      results = {}

      results[:max] = result_times.max
      results[:min] = result_times.min
      results[:avg] = result_times.inject(0.0){|r,i| r+=i }/result_times.size

      results
    end

    private

    def init_eventmachine
      unless EM.reactor_running?
        EM.epoll; EM.kqueue
        EM.error_handler do |ex|
          $log.fatal("Eventmachine problem")
          $log.fatal("#{ex}, tracelog : \n#{ex.backtrace.join("\n")}")
        end
      end
    end

    def run_cmd(cmd)
      require "open3"
      begin
        results = Open3.capture3(cmd)
        return results
      rescue =>e
        $log.warn "[SystemCommond]E:" + e
        return false
      end
    end

  end
end

