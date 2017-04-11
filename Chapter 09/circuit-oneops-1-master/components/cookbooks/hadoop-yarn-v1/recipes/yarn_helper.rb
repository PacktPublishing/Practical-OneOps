#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: yarn_helper.rb
#
#

# pulls in the custom paylaod with all the shared attributes, parses the json
# and shoves it into a dictionary
def getCia()
    require 'json'

    # read in ciAttributes from custom payload
    cia_payload = node.workorder.payLoad.yarnconfigci
    # parse json and shove into a dictionary
    cia = JSON.parse(cia_payload[0].to_json)["ciAttributes"]

    return cia
end


# determines and returns the resource manager- there is a potential for multiple
# resource managers since one gets deployed per cloud when deploying to multiple
# clouds.  this ensures the same resource manager is used among the clouds
def getRm()
    # load in shared attributes
    cia = getCia()

    # get list of all computes
    nodes = node.workorder.payLoad.RequiresComputes
    prmNodesHash = Hash.new
    prmNodesList = Array.new
    # generate a map of prmNodesHash[compute_instance_name] = ip
    nodes.each do |n|
        case n[:ciName]
        when /^prm/
            prmNodesList.push(n.ciAttributes.instance_name)
            prmNodesHash[n.ciAttributes.instance_name] = n.ciAttributes.private_ip
        end
    end
    # sort hash by key and grab first element as the primary resource manager
    prmNode = prmNodesHash[prmNodesList.sort[0]]
    # until HA is implemented, setting the secondary resource manager as the same
    # as the primary
    srmNode = prmNode

    # if the primary resource manager is specified in the platform design so that
    # a client can point to an existing cluster, use that ip instead.
    unless cia["hive_standalone_namenode"].include? 'some_hostname_or_ip'
        prmNode = cia["hive_standalone_namenode"]
    end

    return prmNode, srmNode
end


# ingest true/false string, returns coresponding bool
def toBool(str)
    str.downcase == 'true'
end


# returns new or existing keystore private and public passwords
def getKeystorePass()
    require 'nokogiri'

    # load in shared attributes
    cia = getCia()

    # set up variables specified in the shared attributes
    hive_install_dir = cia["hive_install_dir"]
    hive_site_file = "#{hive_install_dir}/hive/conf/hive-site.xml"
    pub_pass_file = "#{hive_install_dir}/hive/conf/keystore/pub_truststore_pass"
    keystore_file = "#{hive_install_dir}/hive/conf/keystore/#{node.hostname}.keystore"

    # if hive-site.xml already exists, read in the private password value specified
    if File.exist? File.expand_path hive_site_file
        @hivesite = Nokogiri::XML(File.open(hive_site_file))
        private_pass = @hivesite.xpath("/configuration/property[name[text()='hive.server2.keystore.password']]/value").collect {|node| node.text.strip}
        private_pass = private_pass[0]
    else
        private_pass = ""
    end

    # if the private password has not been set or if the keystore does not exist
    # generate a new random private password
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    if private_pass.empty? or not File.exist? File.expand_path keystore_file
        private_pass = (0...50).map { o[rand(o.length)] }.join
    end

    # if the public password file and keystore does not exist, generate new pub pass
    if File.exist? File.expand_path pub_pass_file and File.exist? File.expand_path keystore_file
        public_pass = File.read(pub_pass_file)
    else
        public_pass = (0...50).map { o[rand(o.length)] }.join
    end

    return private_pass, public_pass
end


# returns a list of the fqdns of all the computes in an environment
def getFqdns()
    require 'json'

    # grab the raw custom payload with the fqdns of all the computes
    allfqdn_payload = node.workorder.payLoad.allFqdn

    # parse the raw payload and stuff into a dictionary
    allfqdn_json = JSON.parse(allfqdn_payload.to_json)

    fqdns = Array.new
    # parse out the json and pick out the fqdns
    for ciAttributes in allfqdn_json
        entries = JSON.parse(ciAttributes["ciAttributes"].to_json)
        if entries.has_key?("entries")
            # the below is pretty janky, but i could not figure out how to properly parse the remaining
            # json to pick out what i needed, the result is a bunch of splits to pick out the part i needed
            fqdns.push(entries["entries"].split(",")[0].split(":")[0].split("{")[1].split("\"")[1])
        end
    end

    return fqdns
end


# checks if given string is a valid url
def isValidUrl(url)
    require 'uri'
    # require 'faraday'

    # if url =~ /\A#{URI::regexp(['http', 'https'])}\z/ and Faraday.get(url).status == 200
    if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
        return true
    else
        return false
    end
end

# returns number of cores to be used
def getCoreConfig()
    # load in shared attributes
    cia = getCia()

    if cia["use_all_cores"] == true || cia["use_all_cores"] == 'true'
        cores = node.cpu.total.to_i
    elsif node.cpu.total.to_i <= 2
        cores = node.cpu.total.to_i
    elsif node.cpu.total.to_i <= 4
        cores = node.cpu.total.to_i - 1
    else
        cores = node.cpu.total.to_i - 2
    end

    return cores
end

# returns memory configuration
def getMemoryConfigs()
    node_memory_in_gb = node.memory.total.to_i / 1024 / 1024;
    if node_memory_in_gb <= 2
        total_available_memory_in_mb = 1920
        num_of_containers = 3
    elsif node_memory_in_gb <= 4
        total_available_memory_in_mb = 1024 * ( node_memory_in_gb - 2 )
        num_of_containers = [2 * node.cpu.total.to_i, (node_memory_in_gb - 2) * 4].min
    elsif node_memory_in_gb <= 6
        total_available_memory_in_mb = 1024 * ( node_memory_in_gb - 2 )
        num_of_containers = [2 * node.cpu.total.to_i, (node_memory_in_gb - 2) * 2].min
    elsif node_memory_in_gb <= 8
        total_available_memory_in_mb = 1024 * ( node_memory_in_gb - 3 )
        num_of_containers = [2 * node.cpu.total.to_i, (node_memory_in_gb - 3) * 2].min
    elsif node_memory_in_gb <= 24
        total_available_memory_in_mb = 1024 * ( node_memory_in_gb - 4 )
        num_of_containers = [2 * node.cpu.total.to_i, node_memory_in_gb - 4].min
    else
        total_available_memory_in_mb = 1024 * ( node_memory_in_gb - 4 )
        num_of_containers = [2 * node.cpu.total.to_i, (node_memory_in_gb - 4) / 2].min
    end

    container_memory = total_available_memory_in_mb / num_of_containers
    map_memory = container_memory

    if container_memory < 2048
        reduce_memory = 2 * container_memory
    else
        reduce_memory = container_memory
    end

    return map_memory, reduce_memory, container_memory, total_available_memory_in_mb
end
