module Printfection
  class Resource
    module Operations
      module Retrieve
        module ClassMethods
          def retrieve(id)
            new Printfection.get [self.url, id].join("/")
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
        end
      end

      module List
        module ClassMethods
          def list
            Printfection.get(self.url).map do |response|
              new response
            end
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
        end
      end

      module Create
        module ClassMethods
          def create(params)
            new Printfection.post(self.url, params)
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
        end
      end

      module Update
        def save
          Printfection.patch [self.class.url, id].join("/"), changes
        end
      end

      module Delete
        def delete
          Printfection.delete [self.class.url, id].join("/")
        end
      end
    end

    def self.expose(attribute, options={})
      attribute = attribute.to_s
      type = options[:as]
      readonly = options[:readonly]

      case type
      when :boolean
        expose_boolean(attribute)
      when :integer
        expose_integer(attribute)
      when :float
        expose_float(attribute)
      when :string
        expose_string(attribute)
      when :datetime
        expose_datetime(attribute)
      when :object
        expose_object(attribute)
      else
        expose_raw(attribute)
      end

      unless readonly
        expose_setter(attribute)
      end
    end

    def self.expose_raw(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}(&block)
           data[:#{attribute}]
         end
      EOS
    end

    def self.expose_boolean(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}(&block)
           Util.to_bool(data[:#{attribute}])
         end

         def #{attribute}?(&block)
           #{attribute}
         end
      EOS
    end

    def self.expose_integer(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}(&block)
           data[:#{attribute}].to_i
         end
      EOS
    end

    def self.expose_float(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}(&block)
           data[:#{attribute}].to_f
         end
      EOS
    end

    def self.expose_string(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}(&block)
           data[:#{attribute}].to_s
         end
      EOS
    end

    def self.expose_datetime(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}(&block)
           DateTime.parse(data[:#{attribute}])
         end
      EOS
    end

    def self.expose_object(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}(&block)
           OpenStruct.new(data[:#{attribute}])
         end
      EOS
    end

    def self.expose_setter(attribute)
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
         def #{attribute}=(value, &block)
           data[:#{attribute}] = value
         end
      EOS
    end

    def initialize(data={})
      @clean_data = data.dup
      @dirty_data = data.dup
    end

    def data
      dirty_data
    end

    def dirty_data
      @dirty_data
    end

    def clean_data
      @clean_data
    end

    def changes
      dirty_data.keys.inject({}) do |diff, key|
        unless dirty_data[key] == clean_data[key]
          diff[key] = dirty_data[key]
        end
        diff
      end
    end

  end
end

