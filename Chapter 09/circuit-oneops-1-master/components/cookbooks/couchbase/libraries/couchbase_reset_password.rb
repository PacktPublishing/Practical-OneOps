require 'pty'
require 'expect'

module Couchbase
    class CouchbaseResetPassword

        @@cbreset_password='/opt/couchbase/bin/cbreset_password'
        @@timeout=120

        def initialize()
          
        end

        def reset_password(new_password)
          begin
            PTY.spawn("sudo #{@@cbreset_password}") do |r, w, pid|
              r.expect('Please enter the new administrative password (or <Enter> for system generated password):', @@timeout)
              w.puts(new_password)
              
              r.expect('Do you really want to do it? (yes/no)', @@timeout)
              w.puts('yes')
              
              r.expect('Password for user Administrator was successfully replaced.', @@timeout)
            end
          rescue Exception => e
            puts "Unable to reset password #{e}"
          end          
        end
    end
end
