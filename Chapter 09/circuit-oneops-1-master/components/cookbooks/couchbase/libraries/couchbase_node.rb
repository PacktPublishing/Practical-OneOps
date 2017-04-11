#require './libraries/couchbase_cli'

module Couchbase
    class CouchbaseNode

        attr_reader :ip, :username, :password
        @cli

        def initialize(ip, username, password)
            @ip = ip
            @username = username
            @password = password
            @cli = Couchbase::CouchbaseCLI.new(ip, username, password)
        end

        def info

            @cli.server_info(@ip, @username, @password)

        end

    end
end
