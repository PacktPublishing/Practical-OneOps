require 'json'
require 'net/http'
require 'socket'
require 'logger'
require 'uri'

class CouchbaseMonitor

  attr_accessor :hostname, :prefix, :username, :password, :graphite_hosts,
                :environment, :cloudname, :tcp_sockets,
                :graphite_logfiles_path, :rotate,  :log_size,
                :logger, :healthy_nodes, :failover_nodes


  CONST_CLUSTER_LEVEL = 1
  CONST_NODE_LEVEL = 2
  CONST_BUCKET_LEVEL = 3
  CONST_MAX_LOG_FILE_ROTATION_DAYS = 10
  CONST_MAX_LOG_FILE_SIZE = 10 * 1024 * 1024
  CONST_CBSTATS_FILE_PREFIX = 'cbstats'

  #Constructor to initialize this class with input parameters
  def initialize(hostname, user, password, graphite_hosts,
                 prefix, env, cloud,
                 graphite_logfiles_path, rotate,  log_size)

    @hostname = "http://#{hostname}"
    @username = user
    @password = password
    @graphite_hosts = graphite_hosts
    @prefix = prefix
    @environment = env
    @cloudname = cloud
    @graphite_logfiles_path = graphite_logfiles_path

    #Use defaults if log file rotation isn't set up
    if (rotate == nil || rotate == 0)
      rotate = CONST_MAX_LOG_FILE_ROTATION_DAYS
    end
    @rotate = rotate

    #Use defaults if log file size isn't set up
    if (log_size == nil || log_size == 0)
      log_size =  CONST_MAX_LOG_FILE_SIZE
    end
    @log_size = log_size
    @logger = Logger.new(@graphite_logfiles_path, @rotate,  @log_size)
    @healthy_nodes = 0
    @failover_nodes = 0

    # Setting logging level to Error for the initial version. The plan
    # is to accept it as an incoming parameter in the future.
    logger.level = Logger::ERROR
  end

  #All REST calls are made through here
  def rest_call(endpoint)
    logger.info "rest_call:start: for endpoint = #{endpoint}"

    uri = URI.parse(endpoint)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@username, @password)
    response = http.request(request)
    logger.info 'rest_call:end: Completed'

    return response.body

  end

  #Opens tcp sockets to all graphite servers on the specified port#
  def open_tcp_sockets()
    logger.info "open_tcp_sockets:start: graphite host list = #{@graphite_hosts}"

    if (@graphite_hosts.length > 0)

      @tcp_sockets = Array.new
      graphite_hosts.each do |graphite_host|
        begin
          graphite_server = graphite_host.split(':')[0]
          port = graphite_host.split(':')[1]
          tcp_socket = TCPSocket.new(graphite_server, port)
          @tcp_sockets.insert(-1, tcp_socket)
        rescue Exception => e
          logger.error "open_tcp_sockets:exception: graphite host = #{graphite_host} #{e}"
        end
      end

    end

    logger.info 'open_tcp_sockets:end: Completed'

  end


  #Close tcp sockets to all graphite servers
  def close_tcp_sockets()
    logger.info "close_tcp_sockets:start: tcp sockets list = #{@tcp_sockets}"

    if (@tcp_sockets.length > 0)

      @tcp_sockets.each do |tcp_socket|
        begin
          tcp_socket.close
        rescue Exception => e
          logger.error "close_tcp_sockets:exception: #{e}"
        end
      end

    end

    logger.info 'close_tcp_sockets:end: Completed'

  end


  #Iterates through a list of graphite hosts, opens up a TCP connection and
  #writes the metrics out to the graphite server
  def write_to_graphite(key, value, time = Time.now)
    logger.info "write_to_graphite:start: key = #{key}, value = #{value}, time = #{time.to_i}"

    if (@tcp_sockets.length > 0)

      @tcp_sockets.each do |tcp_socket|

        begin
          tcp_socket.write("#{key} #{value.to_f} #{time.to_i}\n")
          #puts key, value, time.to_i
        rescue Exception => e
          logger.error "write_to_graphite:exception: #{e}"
        end
      end

    end
    logger.info 'write_to_graphite:end: Completed'

  end


  def basic_check(url)
    logger.info "basic_check:start: url = #{url}"
    jsonResponse = rest_call(url)
    myHash = JSON.parse(jsonResponse)
    puts myHash["isAdminCreds"]
    puts myHash["settings"]["maxParallelIndexers"]
    puts myHash["componentsVersion"]["ns_server"]
    logger.info 'basic_check:end: Completed'
  end


  #Construct the metric name
  #May be cluster level (1), node level (2) or bucket level (3)
  def construct_metric_name(metric_name, level)
    logger.info "construct_metric_name:start: metric_name = #{metric_name}, level = #{level}"
    # The logic for adding 'DF.' is going to be the responsibility of the cron job
    # invoking this ruby script. That way the caller is aware of the
    final_metric_name = "#{@prefix}.#{@environment}.cache.#{@cloudname}."

    case level
      when CONST_CLUSTER_LEVEL
        final_metric_name += metric_name
      when CONST_NODE_LEVEL
        final_metric_name += 'nodes'.concat('.').concat( metric_name)
      when CONST_BUCKET_LEVEL
        final_metric_name += 'buckets'.concat('.').concat( metric_name)
    end
    logger.info "construct_metric_name:end: final_metric_name = #{final_metric_name}"

    return final_metric_name
  end


  #Gather cluster statistics and stream it to the graphite servers
  def cluster_stats(url, time)

    logger.info "cluster_stats:start: url = #{url}, time = #{time.to_i}"

    jsonResponse = rest_call(url)
    response_hash = JSON.parse(jsonResponse)
    #puts response_hash
    node_count = response_hash['nodes'].count
    nodes = response_hash['nodes']

    #puts "Total number of nodes in the cluster = #{node_count.to_s}"

    #rebalance status in the cluster
    rebalanceStatus = response_hash['rebalanceStatus']
    rebalance = rebalanceStatus.eql?('none') ? 0 : 1

    #ram metrics in the cluster
    ram_total = response_hash['storageTotals']['ram']['total']
    ram_quota_total = response_hash['storageTotals']['ram']['quotaTotal']
    ram_quota_used = response_hash['storageTotals']['ram']['quotaUsed']
    ram_used = response_hash['storageTotals']['ram']['used']
    ram_used_by_data = response_hash['storageTotals']['ram']['usedByData']
    ram_quota_used_per_node = response_hash['storageTotals']['ram']['quotaUsedPerNode']
    ram_quota_total_per_node = response_hash['storageTotals']['ram']['quotaTotalPerNode']

    #cluster RAM level stats
    write_to_graphite( construct_metric_name('rebalance', CONST_CLUSTER_LEVEL), rebalance, time)
    write_to_graphite( construct_metric_name('ram_total', CONST_CLUSTER_LEVEL), ram_total.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_total', CONST_CLUSTER_LEVEL), ram_quota_total.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_used', CONST_CLUSTER_LEVEL), ram_quota_used.to_s, time)
    write_to_graphite( construct_metric_name('ram_used', CONST_CLUSTER_LEVEL), ram_used.to_s, time)
    write_to_graphite( construct_metric_name('ram_used_by_data', CONST_CLUSTER_LEVEL), ram_used_by_data.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_used_per_node', CONST_CLUSTER_LEVEL), ram_quota_used_per_node.to_s, time)
    write_to_graphite( construct_metric_name('ram_quota_total_per_node', CONST_CLUSTER_LEVEL), ram_quota_total_per_node.to_s, time)

    #HDD metrics in the cluster
    hdd_total = response_hash['storageTotals']['hdd']['total']
    hdd_quota_total = response_hash['storageTotals']['hdd']['quotaTotal']
    hdd_used = response_hash['storageTotals']['hdd']['used']
    hdd_used_by_data = response_hash['storageTotals']['hdd']['usedByData']
    hdd_free = response_hash['storageTotals']['hdd']['free']

    #cluster HDD level stats
    write_to_graphite( construct_metric_name('hdd_total', CONST_CLUSTER_LEVEL), hdd_total.to_s, time)
    write_to_graphite( construct_metric_name('hdd_quota_total', CONST_CLUSTER_LEVEL), hdd_quota_total.to_s, time)
    write_to_graphite( construct_metric_name('hdd_used', CONST_CLUSTER_LEVEL), hdd_used.to_s, time)
    write_to_graphite( construct_metric_name('hdd_used_by_data', CONST_CLUSTER_LEVEL), hdd_used_by_data.to_s, time)
    write_to_graphite( construct_metric_name('hdd_free', CONST_CLUSTER_LEVEL), hdd_free.to_s, time)

    nodes.each do |node|

      #systemStats
      swap_total = node['systemStats']['swap_total']
      swap_used = node['systemStats']['swap_used']
      mem_total = node['systemStats']['mem_total']
      mem_free = node['systemStats']['mem_free']

      #interestingStats
      cmd_get = node['interestingStats']['cmd_get']
      couch_docs_actual_disk_size = node['interestingStats']['couch_docs_actual_disk_size']
      couch_docs_data_size = node['interestingStats']['couch_docs_data_size']
      curr_items = node['interestingStats']['curr_items']
      curr_items_tot = node['interestingStats']['curr_items_tot']
      ep_bg_fetched = node['interestingStats']['ep_bg_fetched']
      get_hits = node['interestingStats']['get_hits']
      mem_used = node['interestingStats']['mem_used']
      ops = node['interestingStats']['ops']
      vb_replica_curr_items = node['interestingStats']['vb_replica_curr_items']

      clusterMembership = node['clusterMembership']
      status = node['status']
      otpNode = node['otpNode']
      otpNode = otpNode.gsub('.','-')


      if (status =='healthy' && clusterMembership == 'active' )
        @healthy_nodes += 1
      end

      if (clusterMembership == 'inactiveFailed' )
        @failover_nodes += 1
      end

      #node level systemStats
      write_to_graphite( construct_metric_name("#{otpNode}.swap_total", CONST_NODE_LEVEL), swap_total.to_s, time)
      write_to_graphite( construct_metric_name("#{otpNode}.swap_used", CONST_NODE_LEVEL), swap_used.to_s, time)
      write_to_graphite( construct_metric_name("#{otpNode}.mem_total", CONST_NODE_LEVEL), mem_total.to_s, time)
      write_to_graphite( construct_metric_name("#{otpNode}.mem_free", CONST_NODE_LEVEL), mem_free.to_s, time)


      #node level interestingStats
      write_to_graphite( construct_metric_name("#{otpNode}.cmd_get", CONST_NODE_LEVEL), cmd_get, time)
      write_to_graphite( construct_metric_name("#{otpNode}.couch_docs_actual_disk_size", CONST_NODE_LEVEL), couch_docs_actual_disk_size, time)
      write_to_graphite( construct_metric_name("#{otpNode}.couch_docs_data_size", CONST_NODE_LEVEL), couch_docs_data_size, time)
      write_to_graphite( construct_metric_name("#{otpNode}.curr_items", CONST_NODE_LEVEL), curr_items)
      write_to_graphite( construct_metric_name("#{otpNode}.curr_items_tot", CONST_NODE_LEVEL), curr_items_tot, time)
      write_to_graphite( construct_metric_name("#{otpNode}.ep_bg_fetched", CONST_NODE_LEVEL), ep_bg_fetched, time)
      write_to_graphite( construct_metric_name("#{otpNode}.get_hits", CONST_NODE_LEVEL), get_hits, time)
      write_to_graphite( construct_metric_name("#{otpNode}.mem_used", CONST_NODE_LEVEL), mem_used, time)
      write_to_graphite( construct_metric_name("#{otpNode}.ops", CONST_NODE_LEVEL), ops, time)
      write_to_graphite( construct_metric_name("#{otpNode}.vb_replica_curr_items", CONST_NODE_LEVEL), vb_replica_curr_items, time)

    end


    healthy = nodes.length == @healthy_nodes ? 1 : 0
    write_to_graphite( construct_metric_name('healthy_node_num', CONST_CLUSTER_LEVEL), @healthy_nodes.to_s, time)
    write_to_graphite( construct_metric_name('node_num', CONST_CLUSTER_LEVEL), nodes.length.to_s, time)
    write_to_graphite( construct_metric_name('healthy', CONST_CLUSTER_LEVEL), healthy.to_s, time)

    logger.info 'cluster_stats:end: Completed'
  end

  def get_host(url)
    url = 'http://' + url unless url.match(/^http:\/\//)
    uri = URI.parse(url)
    host = uri.host.downcase
    return host
  end

  # Collects get_cmd metrics from cbstats and performs delta calculations between runs to compute percentile ranges
  def get_cmd_histogram(bucket, node, bucket_password, memcache_port, time)

    logger.info "get_cmd_histogram:start: bucket = #{bucket}, node = #{node}, memcache_port = #{memcache_port}, time = #{time.to_i}"

    #host = node.sub(':8091', '').sub('http://', '')
    host = get_host(node)

    if host == nil
      logger.error "get_cmd_histogram:exception: host #{node} cannot be null"
      return
    end

    if (host == 'localhost')
      ip_address = IPSocket.getaddress(Socket.gethostname)
      otpNode = "ns_1@#{ip_address.gsub('.','-')}"
    else
      otpNode = "ns_1@#{host.gsub('.','-')}"
    end

    # Prepare cbstats command
    cbstatsCLI = CouchbaseStatsCLI.new
    response = cbstatsCLI.get_stats(bucket, bucket_password,
                                    host, memcache_port,
                                    main_command = 'timings', sub_command = 'get_cmd')
    #puts response.split('storage_age')[0]

    if (response.index('get_cmd') == nil)
      logger.info "No results returned from cbstats command for bucket: #{bucket}"
      return
    end

    current_get_ops_response = response.split('storage_age')[0].lines.to_a
    last_position = current_get_ops_response.length - 2

    # Extract total get ops performed
    current_total_get_ops = current_get_ops_response[0].split('(')[1].to_f
    current_get_ops_hash = Hash.new

    # Create hash of upper time limit as key and get ops as value
    current_get_ops_response[1..last_position - 1].each do |this_line|
      current_get_ops_hash["#{this_line.split(':')[0].split('-')[1].strip}"] = this_line.split(')')[1].split(' ')[0].to_f
    end

    # puts "==================================="
    # puts current_get_ops_hash
    # puts "Current total get ops = #{current_total_get_ops}"
    # puts "==================================="

    current_running_total = 0.0
    previous_total_get_ops = 0.0

    # Check if cbstats file exists. This implies there's been a previous run
    previous_get_ops_hash = Hash.new
    fileName = CONST_CBSTATS_FILE_PREFIX + "_#{bucket.downcase}.txt"

    if (File.exist?(fileName))
      oldfile = File.open(fileName, 'r')
      metrics_str = oldfile.read
      oldfile.close
      previous_get_ops_hash = eval(metrics_str)
      previous_get_ops_hash.each {|key, value| previous_total_get_ops += value}
      # puts "Previous get ops = #{metrics_str}"
      # puts "Previous total get ops = #{previous_total_get_ops}"
      # puts "==================================="
    end

    # Compare previous and current get ops metrics
    if (current_get_ops_hash == previous_get_ops_hash)
      logger.info 'No ops between the last two runs'
      return
    end

    percentiles_hash = Hash.new

    current_get_ops_hash.each {|key, current_value|
      previous_value = previous_get_ops_hash.has_key?(key)? previous_get_ops_hash[key] : 0.0

      if (current_value != previous_value)
        current_running_total += current_value - previous_value
        percentile = (current_running_total / (current_total_get_ops - previous_total_get_ops) ) * 100
        percentiles_hash[key] = percentile.round(2)
      end
    }

    # Write hash to file
    file = File.open(fileName, 'w')
    file.write(current_get_ops_hash)
    file.close

    #puts "Percentile Result = #{percentiles_hash}"

    # Read the driver percentile ranges from config file. If the file doesn't exist, create it
    if File.exist?('percentile_ranges.txt')
      driver_percentile_range = eval(File.open('percentile_ranges.txt', 'r') { |file| file.readline })
    else
      driver_percentile_range = [25, 50, 75, 90, 95, 99, 100]
      conf_file = File.open('percentile_ranges.txt', 'w')
      conf_file.write(driver_percentile_range)
      conf_file.close
    end

    microsecond_percentile_hash = percentiles_hash.map {|key, value|
      [
          key.include?('us') ? key[0..key.index('us')-1].to_i : key[0..key.index('ms')-1].to_i * 1000,
          value
      ]
    }

    sorted_percentile_hash = microsecond_percentile_hash.sort

    driver_percentile_range.each { |percentile|
      metric_name = construct_metric_name("#{otpNode}.buckets.#{bucket}.cmd_get_timing.#{percentile}_pctile", CONST_NODE_LEVEL)

      if percentile < 100
        key_value = sorted_percentile_hash.select {|key, value| value >= percentile}.first().join(':')
      else
        key_value = sorted_percentile_hash.select {|key, value| value >= percentile}.last().join(':')
        end

      #puts "#{metric_name} = #{time_us}"
      write_to_graphite(metric_name, time_us, time)
    }


    logger.info 'get_cmd_histogram: Completed'
  end


  #Collects all bucket level metrics from the cluster and stream it to graphite clusters
  def bucket_stats(url, time)

    logger.info "bucket_stats:start: url = #{url}, time = #{time.to_i}"

    jsonResponse = rest_call(url)
    buckets = JSON.parse(jsonResponse)

    buckets.each do |bucket|
      bucket_name = bucket['name'].gsub(/\./, '-')
      replica_num =  bucket['replicaNumber']
      ram_quota = bucket['quota']['ram']
      ram_quota_raw = bucket['quota']['rawRAM']
      quota_percent_used = bucket['basicStats']['quotaPercentUsed']
      ops_per_sec = bucket['basicStats']['opsPerSec']
      disk_fetches = bucket['basicStats']['diskFetches']
      item_count = bucket['basicStats']['itemCount']
      disk_used = bucket['basicStats']['diskUsed']
      data_used = bucket['basicStats']['dataUsed']
      mem_used = bucket['basicStats']['memUsed']
      node_size = bucket['nodes'].length

      data_availability_pct = data_availability(node_size, replica_num, @healthy_nodes, @failover_nodes)

      write_to_graphite( construct_metric_name("#{bucket_name}.replica_num", CONST_BUCKET_LEVEL), replica_num.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.quota_percent_used", CONST_BUCKET_LEVEL), quota_percent_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.ops", CONST_BUCKET_LEVEL), ops_per_sec.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.mem_used", CONST_BUCKET_LEVEL), mem_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.item_cnt", CONST_BUCKET_LEVEL), item_count.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.disk_used", CONST_BUCKET_LEVEL), disk_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.disk_fetches", CONST_BUCKET_LEVEL), disk_fetches.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.data_used", CONST_BUCKET_LEVEL), data_used.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.ram_quota", CONST_BUCKET_LEVEL), ram_quota.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.ram_quota_raw", CONST_BUCKET_LEVEL), ram_quota_raw.to_s, time)
      write_to_graphite( construct_metric_name("#{bucket_name}.data_availability_pct", CONST_BUCKET_LEVEL), data_availability_pct.to_s, time)

      get_cmd_histogram(bucket_name, @hostname , @password, 11210, time)

    end

    logger.info 'bucket_stats:end: Completed'
  end


  def time_socket_open_close(ip, port, seconds=2.5)
    begin
      beginning_time = Time.now
      Timeout::timeout(seconds) do
        begin
          TCPSocket.new(ip, port).close
          diff_millis = (Time.now - beginning_time)*1000;
          logger.info("Check ip:#{ip} port:#{port}. Time: #{diff_millis} milliseconds")
          return diff_millis
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
          diff_millis = (Time.now - beginning_time)*1000;
          logger.error("Check ip:#{ip} port:#{port} closed  #{diff_millis} milliseconds #{e.message}")
          return diff_millis
        end
      end
    rescue Timeout::Error
      diff_millis = (Time.now - beginning_time)*1000;
      logger.error("Check ip:#{ip} port:#{port} Time elapsed #{diff_millis} milliseconds")
      return diff_millis
    end
  end

  # Collects ping metrics across all nodes in the cluster
  def ping_stats(url, time)

    logger.info "ping_stats:start: url = #{url}, time = #{time.to_i}"

    jsonResponse = rest_call(url)
    response_hash = JSON.parse(jsonResponse)
    nodes = response_hash['nodes']

    this_node = nodes.select { |node| node.has_key?('thisNode') && node['thisNode'] == true }.first

    if this_node != nil
      nodes.each do |node|
        if node['otpNode'] != this_node['otpNode']
          hostname = URI.parse("http://#{node['hostname']}").host.downcase
          ping_time = time_socket_open_close(hostname, '22')
          write_to_graphite( construct_metric_name("#{this_node['otpNode'].gsub('.','-')}.ping.#{hostname.gsub('.','-')}", CONST_NODE_LEVEL), ping_time, time)
        end
      end
    else
      logger.info 'No nodes found with thisNode == true'
    end

    logger.info 'ping_stats:end: Completed'
  end

  #Primary entrance point to collect all metrics from the cluster
  def collect_all_stats()

    begin
      logger.info 'collect_all_stats:start: Starting'

      cluster_stats_url = "#{@hostname}/pools/default"
      bucket_stats_url  = "#{@hostname}/pools/default/buckets"

      time = Time.now

      open_tcp_sockets

      cluster_stats(cluster_stats_url, time)

      bucket_stats(bucket_stats_url, time)

      ping_stats(cluster_stats_url, time)

      close_tcp_sockets

      logger.info 'collect_all_stats:end: Completed'
    rescue Exception => e
      logger.error "collect_all_stats:exception: #{e}"
    end
  end


  #Custom formula to compute data availability for a bucket
  def data_availability(node_size, replica_count, healthy_nodes, failover_nodes)

    logger.info "data_availability:start: node_size = #{node_size}, replica_count = #{replica_count},
      healthy_nodes = #{healthy_nodes}, failover_nodes = #{failover_nodes}"

    data_percent_per_node = 1.0 / node_size
    replica_data_percent_per_node = data_percent_per_node * replica_count
    replica_data_percent_per_node_with_failover = 0
    availability = 0

    if (0 < failover_nodes)
        replica_data_percent_per_node_with_failover = replica_data_percent_per_node / (node_size - failover_nodes)
    end

    availability = (data_percent_per_node + replica_data_percent_per_node_with_failover) * healthy_nodes

    if (availability > 1)
        availability = 1
    end
    return_value = "#{'%.2f' % (availability * 100)}"

    logger.info "data_availability:end: return_value = #{return_value}"

    return return_value

  end

end


class CouchbaseStatsCLI

  CONST_COUCHBASE_HOME_DIR = '/opt/couchbase/bin/'

  def get_stats(bucket, bucket_password, node = 'localhost', memcache_port = 11210, main_command = 'timings', sub_command = 'get_cmd')
    # Prepare cbstats command
    if (bucket_password == nil)
      command = "#{CONST_COUCHBASE_HOME_DIR}cbstats #{node}:#{memcache_port} -b #{bucket} #{main_command} | grep #{sub_command} -A22"
    else
      command = "#{CONST_COUCHBASE_HOME_DIR}cbstats #{node}:#{memcache_port} -b #{bucket} -p #{bucket_password} #{main_command} | grep #{sub_command} -A22"
    end

    begin
      #puts "command : #{command}"
      # Execute cbstats command
      response = `#{command}`
      return response

    rescue Exception => e
      logger.error "CouchbaseStatsCLI.get_stats:exception: cbstats command failed. Command: #{command} Reason: #{e}"
      return
    end

  end

end

