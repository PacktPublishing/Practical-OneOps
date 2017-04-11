module Couchbase
    class CouchbaseBucket

        attr_reader :name, :password

        def initialize(name, password)
            @name = name
            @password = password
        end

    end
end
