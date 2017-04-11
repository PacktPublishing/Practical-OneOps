module Couchbase
  class CouchbaseProcess

    @@command='sudo /etc/init.d/couchbase-server'

    def start
      %x(#{start_command})
    end

    def stop
      %x(#{stop_command})

    end

    def status
      %x(#{status_command})
    end

    def start_command
      "#{@@command} start"
    end

    def stop_command
      "#{@@command} stop"
    end

    def status_command
      "#{@@command} status"
    end

  end
end
