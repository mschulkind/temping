require "active_record"
require "active_support/core_ext/string"

class Temping
  def self.create(model_name, &block)
    factory = ModelFactory.new(model_name.to_s.classify, &block)
    factory.build
  end

  class ModelFactory
    def initialize(model_name, &block)
      @model_name = model_name
      @block = block
    end

    def build
      Class.new(ActiveRecord::Base).tap do |klass|
        @klass = klass

        if Object.const_defined?(@model_name)
          Object.send(:remove_const, @model_name)
        end

        Object.const_set(@model_name, klass)

        klass.primary_key = :id
        create_table
        add_methods

        klass.class_eval(&@block) if @block
      end
    end

    private

    def create_table
      connection.create_table(table_name, :temporary => true, :force => true)
    end

    def add_methods
      class << @klass
        def with_columns
          connection.change_table(table_name) do |table|
            yield(table)
          end
        end

        def table_exists?
          true
        end
      end
    end

    def connection
      @klass.connection
    end

    def table_name
      @klass.table_name
    end
  end
end
