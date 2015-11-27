require 'highcore_sparkle'
require 'sparkle_formation'
require 'json'
require 'yaml'

class HighcoreSparkle

  include HighcoreSparkle::Options

  def self.load_library(path)
    Dir.glob(File.join(path, "*")).each do |library|
       dirs = Dir.glob(File.join(library, "**/*/")) << library
       dirs.each do |dir|
        method = "load_#{File.basename(library)}!"
        SparkleFormation.public_send(method, dir) if SparkleFormation.respond_to? method
      end
    end
  end

  def self.generate(template_path, template_name, stack_definition)

    template_definition = File.join(template_path, "#{template_name}.yml")
    template = Options.symbolize_recursive(YAML.load_file(template_definition))
    template = Options.key_by_id_recursive(template)

    stack_input = JSON.parse(stack_definition, {:symbolize_names => true})
    components_input = stack_input.delete(:components)
    components = Options.generate_components(template, components_input, stack_input)

    template[:requirements].each { |req|
      self.load_library(Gem::Specification.find_by_name(req).gem_dir)
    } if template[:requirements]

    # Load project libraries
    self.load_library(template_path)

    # Load template
    sparkle = SparkleFormation.new(template_name) do
      description "#{template_name} stack"

      @outputs = {}

      components.each do |id, component|
        config = component[:config].clone.merge({:template => template_name})
        registry!(:"#{template_name}_#{component[:template_component]}", component[:id].to_sym, component, config)
      end

      registry!(:outputs, :outputs => @outputs)
      registry!(:parameters, :components => components)
    end
    sparkle.recompile
    sparkle.to_json
  end
end
