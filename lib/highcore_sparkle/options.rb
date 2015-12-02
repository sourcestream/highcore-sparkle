class HighcoreSparkle

  module Options

    def self.symbolize_recursive(obj)
      case obj
        when Array
          obj.map {|v| symbolize_recursive(v)}
        when Hash
          obj.inject({}){|memo,(k,v)| memo[k.to_sym] = (v.is_a?(Hash) or v.is_a?(Array)) ? symbolize_recursive(v) : v; memo}
        else
          obj
      end
    end

    def self.key_by_id_recursive(obj)
      case obj
        when Array
          if obj.select {|value| value.is_a? Hash and value.has_key? :id}.length == obj.length
            Hash[obj.map.with_index { |value, index| [value[:id].to_sym, key_by_id_recursive(value)] }]
          else
            obj
          end
        when Hash
          obj.inject({}){|memo,(k,v)| memo[k] = key_by_id_recursive(v); memo}
        else
          obj
      end
    end

    def self.unify_id(id)
      id.to_s.gsub('-', '')
    end

    def self.unify_components_ids(components)
      components.inject({}){|memo,(k,v)|
        result = v.clone
        id = unify_id(v[:id])
        result[:id] = id
        memo[id.to_sym] = result
        memo
      }
    end

    def self.calculate_value!(option)
      option[:value] ||= option[:default] if option.has_key? :default
      if option[:value] and option.has_key?(:type)
        option[:value] = option[:default] = case option[:type]
               when 'bool'
                 option[:value] = option[:value] == 'false' ? false : true
               when 'json'
                 JSON.parse(option[:value])
               when 'array'
                 option[:value].is_a?(Array) ? option[:value] : option[:value].split(',')
               else
                 option[:value]
             end
      end
    end

    def self.merge_parameters(template_parameters, parameters)
      template_parameters ||= {}
      parameters ||= {}
      merged_parameters = parameters.clone
      template_parameters.each { | id, template_parameter |
        parameter = parameters[id] || {}
        parameter.merge!(template_parameter)
        calculate_value!(parameter)
        merged_parameters[id] = parameter
      }
      merged_parameters
    end

    def self.to_key_value(obj)
      obj.inject({}){|memo,(k,v)|
        nil unless v.has_key?(:value)
        memo[k] = v[:value]
        memo
      }
    end

    def self.generate_components(template, stack_components, stack_parameters)
      stack_parameters = merge_parameters(template[:parameters], stack_parameters)
      stack_parameters.each { |k,v| v[:level] = 'stack' }
      stack_components = unify_components_ids(stack_components)
      stack_components.each { |id, component|
        template_component = template[:components][component[:template_component].to_sym]
        component_parameters = merge_parameters(template_component[:parameters], component[:parameters])
        component_parameters.each { |k,v|
          v[:level] = 'component'
          if v[:value].nil? and stack_parameters[k] and stack_parameters[k][:value]
            v[:value] = stack_parameters[k][:value]
            calculate_value!(v) unless stack_parameters[k][:type]
          end
        }
        component[:parameters] = stack_parameters.merge(component_parameters)
        component[:config] = to_key_value(component[:parameters])
        component[:components] ||= {}
        component[:components] = unify_components_ids(component[:components])
        component[:components].each { |dependency_id, dependency_data|
          component[:components][dependency_id] = stack_components[dependency_id]
        }
      }
      stack_components
    end
  end

end
