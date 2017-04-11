module Q2
  module Activemq_dest_config_util
    DEFAULT_DESTINATION_POLICIES = '
       <destinationPolicy>
          <policyMap>
              <policyEntries>
                 <policyEntry queue=">" >
                    <deadLetterStrategy>
                        <sharedDeadLetterStrategy processExpired="false"/>
                    </deadLetterStrategy>
                </policyEntry>
                <policyEntry topic=">" >
                    <pendingMessageLimitStrategy>
                        <constantPendingMessageLimitStrategy limit="1000"/>
                   </pendingMessageLimitStrategy>
                </policyEntry>
              </policyEntries>
          </policyMap>
       </destinationPolicy>
    '

    DEFAULT_DESTINATION_INTERCEPTERS = '
       <destinationInterceptors>
         <virtualDestinationInterceptor>
           <virtualDestinations>
              <virtualTopic name="VirtualTopic.>" prefix="Consumers.*." selectorAware="false"/>
           </virtualDestinations>
         </virtualDestinationInterceptor>
       </destinationInterceptors>
'
    require 'nokogiri'

    def self.deleteVirtualDest(config_xml, dest_type, dest_name)
        if ('Q' == dest_type || 'T' == dest_type) then 
          return
        end

        locker = File.open('/tmp/activemq.config.lock', File::RDWR|File::CREAT, 0644)
        while true do
            b = locker.flock(File::LOCK_NB|File::LOCK_EX)
            if b == 0
              break
            elsif b == false 
              ##puts "have not got exclusive lock yet.  sleeping..."
              sleep 1
            end
        end

        origxml0 = IO.read(config_xml)
        origxml = origxml0.sub('<broker xmlns="http://activemq.apache.org/schema/core" ', "<broker ")
        origdoc = Nokogiri::XML(origxml)
        interceptors = origdoc.at('destinationInterceptors')
        if ( interceptors == nil ) then
          Chef::Log.info("no interceptors found; no action taken for deleting composite #{dest_type} #{dest_name}")
          locker.close
          return
        end

        if ('compositeTopic' != dest_type && 'virtualTopic' != dest_type && 'compositeQueue' != dest_type) then
          locker.close
          errorMsg =  "destination type has to be either compositeQueue, compositeTopic, or virtualTopic"
          puts "***FAULT:FATAL=#{errorMsg}"
          raise "#{errorMsg}" 
        end

        destpath = 'destinationInterceptors/virtualDestinationInterceptor/virtualDestinations/' + "#{dest_type}" + '[@name="'+"#{dest_name}" +'"]'
       
        virtualdest = origdoc.at(destpath)
        if (virtualdest == nil) then
          Chef::Log.info("no composite destination found; no action taken for deleting composite #{dest_type} #{dest_name}")
          locker.close
          return nil
        end

        #delete this composite destination
        #Chef::Log.info("#{dest_type} #{dest_name} deleted:" + virtualdest.to_html.gsub(/\&gt;/, '>'))
        virtualdest.replace('')
        resultdoc = origdoc.to_html.sub("<broker ", '<broker xmlns="http://activemq.apache.org/schema/core" ')
        File.open(config_xml,"w") { |f| f << resultdoc.gsub(/\&gt;/, '>') }
        #Chef::Log.info( origdoc.to_xhtml(indent:3).gsub(/\&gt;/, '>'))
        locker.close
    end

    def self.processVirtualDest(config_xml, dest_type, dest_name, compositedestdefinition)
        if ( 'Q' == dest_type || 'T' == dest_type ) 
          return 
        end
        
        locker = File.open('/tmp/activemq.config.lock', File::RDWR|File::CREAT, 0644)
        while true do
            b = locker.flock(File::LOCK_NB|File::LOCK_EX)
            if b == 0
              break
            elsif b == false 
              ##puts "have not got exclusive lock yet.  sleeping..."
              sleep 1
            end
        end

        origxml0 = IO.read(config_xml)
        origxml = origxml0.sub('<broker xmlns="http://activemq.apache.org/schema/core" ', "<broker ")
        origdoc = Nokogiri::XML(origxml)
        interceptors = origdoc.at('destinationInterceptors')

        if (compositedestdefinition != nil) 
            compositedestdefinition.strip!
        end

        compositedoc = (compositedestdefinition == nil || compositedestdefinition.empty?) ? nil : Nokogiri::XML(compositedestdefinition)

        #make sure interceptors is not nil or quit
        if ( interceptors == nil ) 
           if (compositedestdefinition == nil) 
              Chef::Log.info("activemq.xml has no destination compositedestdefinition, and there is no valid composite #{dest_type} #{dest_name} definition, nothing to do")
              locker.close
              return
           end

           # add default destinationInterceptors stanza
           brokerdoc = origdoc.at('broker')
           brokerdoc.first_element_child.before(DEFAULT_DESTINATION_INTERCEPTERS)
           interceptors = origdoc.at('destinationInterceptors')
        end

        if ('compositeTopic' != dest_type && 'virtualTopic' != dest_type && 'compositeQueue' != dest_type) 
          #it should never happen; but just in case it happens, we exist here
          locker.close
          errorMsg = "destination type has to be either 'compositeQueue', 'compositeTopic', or 'virtualTopic'"
          puts "***FAULT:FATAL=#{errorMsg}"
          raise "#{errorMsg}"
        end

        compositepath = 'destinationInterceptors/virtualDestinationInterceptor/virtualDestinations/' + "#{dest_type}" + '[@name="'+"#{dest_name}" +'"]'
        compositepath2 = "#{dest_type}" + '[@name="'+"#{dest_name}" +'"]'

        compositedest = origdoc.at(compositepath)
        compositedoc2 = (compositedoc == nil) ? nil : compositedoc.at(compositepath2)

        if (compositedest == nil)
            Chef::Log.info("no composite #{dest_type} #{dest_name} in activemq.xml")
            if (compositedoc2 != nil) 
               # add composite destination
               insert_point = interceptors.at('virtualDestinationInterceptor/virtualDestinations')
               insert_point.first_element_child.before(compositedoc2)
            elsif (compositedestdefinition != nil) 
               locker.close
               errorMsg = "#{dest_type} #{dest_name} defination may have wrong destination name or other problems: #{compositedestdefinition}"
               puts "***FAULT:FATAL=#{errorMsg}"
               raise "#{errorMsg}"
            end
        elsif (compositedoc2 == nil) 
           #GUI has input, but it is an invalid destination policy for the queue/topic
           if (compositedestdefinition != nil) 
             locker.close
             errorMsg = "#{dest_type} #{dest_name} defination may have wrong destination name or other problems: #{compositedestdefinition}"
             puts "***FAULT:FATAL=#{errorMsg}"
             raise "#{errorMsg}"
           end
           # delete composite destination because it is empty or nil from GUI
           Chef::Log.info("new #{dest_type} #{dest_name} is empty; deleting existing entry")
           compositedest.replace('')
        else
           # replace/update composite destination 
           Chef::Log.info("replace/update #{dest_type} #{dest_name}")
           compositedest.replace(compositedoc2)
        end

        resultdoc = origdoc.to_html.sub("<broker ", '<broker xmlns="http://activemq.apache.org/schema/core" ')
        # overwrite original xml config file
        File.open(config_xml,"w")  { |f| f << resultdoc.gsub(/\&gt;/, '>') }
        #Chef::Log.info( origdoc.to_xhtml(indent:3).gsub(/\&gt;/, '>'))
        locker.close
    end


    def self.deleteDestPolicy(config_xml, dest_type, dest_name)

        locker = File.open('/tmp/activemq.config.lock', File::RDWR|File::CREAT, 0644)
        while true do
            b = locker.flock(File::LOCK_NB|File::LOCK_EX)
            if b == 0
              break
            elsif b == false 
              ##puts "have not got exclusive lock yet.  sleeping..."
              sleep 1
            end
        end

       origxml0 = IO.read(config_xml)
       origxml = origxml0.sub('<broker xmlns="http://activemq.apache.org/schema/core" ', "<broker ")
       origdoc = Nokogiri::XML(origxml)
       dest_policies = origdoc.at('destinationPolicy')
       if ( dest_policies == nil )
          Chef::Log.info("no policy found; no action taken for deleting #{dest_type} #{dest_name} destination policy")
          locker.close
          return
       end

       if ( 'T' == dest_type || 'compositeTopic' == dest_type || 'virtualTopic' == dest_type)
           policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@topic="'+"#{dest_name}" +'"]'
       elsif ('Q' == dest_type || 'compositeQueue' == dest_type)
           policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@queue="'+"#{dest_name}" +'"]'
       else
           locker.close
           errorMsg = "destination type has to be either 'topic' or 'queue'"
           puts "***FAULT:FATAL=#{errorMsg}"
           raise "#{errorMsg}"
       end
       dest_policy = origdoc.at(policypath)
       if (dest_policy == nil)
          Chef::Log.info("no policy found; no action taken for deleting #{dest_type} #{dest_name} destination policy")
          locker.close
          return
       end

       #delete this policy
       Chef::Log.info("#{dest_type} #{dest_name} destination policy deleted: " + dest_policy.to_html.gsub(/\&gt;/, '>'))
       dest_policy.replace('')
       resultdoc = origdoc.to_html.sub("<broker ", '<broker xmlns="http://activemq.apache.org/schema/core" ')
       File.open(config_xml,"w") { |f| f << resultdoc.gsub(/\&gt;/, '>') }
       #Chef::Log.info( origdoc.to_xhtml(indent:3).gsub(/\&gt;/, '>'))
       locker.close
    end

    def self.processDestPolicy(config_xml, dest_type, dest_name, policies)
        locker = File.open('/tmp/activemq.config.lock', File::RDWR|File::CREAT, 0644)
        while true do
            b = locker.flock(File::LOCK_NB|File::LOCK_EX)
            if b == 0
              break
            elsif b == false 
              ##puts "have not got exclusive lock yet.  sleeping..."
              sleep 1
            end
        end

        origxml0 = IO.read(config_xml)
        origxml = origxml0.sub('<broker xmlns="http://activemq.apache.org/schema/core" ', "<broker ")
        origdoc = Nokogiri::XML(origxml)
        dest_policies = origdoc.at('destinationPolicy')

        if (!policies.nil?)
            policies.strip!
        end
        if (policies.empty?)
           policies = nil
        end
        policydoc = (policies.nil? || policies.empty?) ? nil : Nokogiri::XML(policies)

        #make sure dest_policies is not nil or quit
        if ( dest_policies == nil )
           if (policies.nil?)
              Chef::Log.info("activemq.xml has no destination policies, and #{dest_type} #{dest_name} has no policy, nothing to do")
              locker.close
              return
           end

           # add default destinationPolicy stanza
           brokerdoc = origdoc.at('broker')
           brokerdoc.first_element_child.before(DEFAULT_DESTINATION_POLICIES)
           dest_policies = origdoc.at('destinationPolicy')
        end

        # Chef::Log.info( dest_policies.to_html )
        if ('T' == dest_type || 'compositeTopic' == dest_type || 'virtualTopic' == dest_type)
            policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@topic="'+"#{dest_name}" +'"]'
            policypath2 = 'policyEntry[@topic="'+"#{dest_name}" +'"]'
        elsif ('Q' == dest_type || 'compositeQueue' == dest_type)
            policypath = 'destinationPolicy/policyMap/policyEntries/policyEntry[@queue="'+"#{dest_name}" +'"]'
            policypath2 = 'policyEntry[@queue="'+"#{dest_name}" +'"]'
        else
            locker.close
            errorMsg =  "destination type has to be either 'topic' or 'queue'"
            puts "***FAULT:FATAL=#{errorMsg}"
            raise "#{errorMsg}"
        end

        dest_policy = origdoc.at(policypath)
        if (policydoc != nil)
            policydoc2 = policydoc.at(policypath2)
        end

        if (dest_policy == nil)
            Chef::Log.info("no destination policy found for #{dest_type} #{dest_name} in activemq.xml")
            if (!policydoc2.nil?)
               # add policyEntry for destination
               insert_point = dest_policies.at('policyMap/policyEntries')
               insert_point.first_element_child.before(policydoc2)
            elsif (policies != nil)
               locker.close
               errorMsg = "#{dest_type} #{dest_name} destinationPolicy may have wrong destination name or other problems: #{policies}"
               puts "***FAULT:FATAL=#{errorMsg}"
               raise "#{errorMsg}"
            end
        elsif (policydoc2.nil?)
            #GUI has input, but it is an invalid destination policy for the queue/topic
            if (!policies.nil?)
              locker.close
              errorMsg = "#{dest_type} #{dest_name} destinationPolicy may have wrong destination name or other problems: #{policies}"
              puts "***FAULT:FATAL=#{errorMsg}"
              raise "#{errorMsg}"
            end
            # delete destination policy entry because it is empty or nil from GUI
            Chef::Log.info("new policyEntry for #{dest_type} #{dest_name} is empty; deleting existing entry")
            dest_policy.replace('')
        else
            # replace/update destination policy entry
            Chef::Log.info("replace/update policyEntry for #{dest_type} #{dest_name}")
            dest_policy.replace(policydoc2)
        end

        #Chef::Log.info( origdoc.to_html
        # overwrite original xml config file
        resultdoc = origdoc.to_html.sub("<broker ", '<broker xmlns="http://activemq.apache.org/schema/core" ')
        File.open(config_xml,"w") { |f| f << resultdoc.gsub(/\&gt;/, '>') }
        #Chef::Log.info( origdoc.to_xhtml(indent:3).gsub(/\&gt;/, '>'))
        locker.close
    end
  end
end
