require "ostruct"
require_relative "ext_kernel"

require_relative "iis_app_pool_root"
require_relative "iis_app_pool_cpu"
require_relative "iis_app_pool_process_model"
require_relative "iis_app_pool_recycling"
require_relative "iis_app_pool_periodic_restart"
require_relative "iis_app_pool_failure"

module OO
  class IIS
    class AppPool

      class NullEntity < OpenStruct
        def nil?; true; end

        def Cpu; OpenStruct.new; end
        def ProcessModel; OpenStruct.new; end
        def Recycling; OpenStruct.new(:PeriodicRestart => OpenStruct.new(:Schedule => [])); end
        def Failure; OpenStruct.new; end

        def Delete_(*attrs, &block); end
      end

      APP_POOL_STATUS = {
        0 => 'starting',
        1 => 'started',
        3 => 'stopping',
        4 => 'stopped',
        5 => 'unknown'
      }

      silence_warnings do
        SECTION = "system.applicationHost/applicationPools"
        APPLICATION_POOL = "ApplicationPool"
      end

      def initialize(web_administration, name)
        @web_administration = web_administration
        @name = name
        reload
      end

      def reload
        @entity = @web_administration.find(APPLICATION_POOL, @name) || NullEntity.new
      end

      def exists?
        not @entity.nil?
      end

      def status
        APP_POOL_STATUS[@entity.getstate]
      end

      def create(attributes = {})
        not exists? and @web_administration.perform { assign_attributes_on_create(attributes) }
      end

      def recycle
        @entity.recycle if exists? and status == 'started'
      end

      def update(attributes)
        exists? and @web_administration.perform { assign_attributes_on_update(attributes) }
      end

      def delete
        @web_administration.delete(APPLICATION_POOL, @name).tap { reload }
      end

      Root::PROPERTIES.each do |method_name|
        define_method(method_name) { root.send(method_name) }
      end

      def root
        Root.new(@entity).attributes
      end

      def cpu
        CPU.new(@entity.Cpu).attributes
      end

      def process_model
        ProcessModel.new(@entity.ProcessModel).attributes
      end

      def recycling
        Recycling.new(@entity.Recycling).attributes
      end

      def periodic_restart
        PeriodicRestart.new(@entity.Recycling.PeriodicRestart).attributes
      end

      def failure
        Failure.new(@entity.Failure).attributes
      end

      protected

      def assign_attributes_on_create(attributes)
        @web_administration.writable_section_for(SECTION) do |section|
          collection = section.Collection
          pool = collection.CreateNewElement("add")
          assign_attributes_to_pool(pool, attributes)
          collection.AddElement(pool)
        end
        reload
      end

      def assign_attributes_on_update(attributes)
        @web_administration.writable_section_for(SECTION) do |section|
          collection = section.Collection
          position = (0..(collection.Count-1)).find { |i| collection.Item(i).GetPropertyByName("name").Value == @name }
          pool = collection.Item(position)
          assign_attributes_to_pool(pool, attributes)
        end
        reload
      end

      private

      def assign_attributes_to_pool(pool, attributes)
        root_attributes = attributes["root"] || {}
        cpu_attributes = attributes["cpu"] || {}
        process_model_attributes = attributes["process_model"] || {}
        recycling_attributes = attributes["recycling"] || {}
        periodic_restart_attributes = attributes["periodic_restart"] || {}
        failure_attributes = attributes["failure"] || {}

        root_attributes["name"] = @name

        cpu = pool.ChildElements.Item("cpu")
        process_model = pool.ChildElements.Item("processModel")
        recycling = pool.ChildElements.Item("recycling")
        periodic_restart = recycling.ChildElements.Item("periodicRestart")
        failure = pool.ChildElements.Item("failure")

        Root.new(pool).assign_attributes(root_attributes)
        CPU.new(cpu).assign_attributes(cpu_attributes)
        ProcessModel.new(process_model).assign_attributes(process_model_attributes)
        Recycling.new(recycling).assign_attributes(recycling_attributes)
        PeriodicRestart.new(periodic_restart).assign_attributes(periodic_restart_attributes)
        Failure.new(failure).assign_attributes(failure_attributes)
      end
    end
  end
end
