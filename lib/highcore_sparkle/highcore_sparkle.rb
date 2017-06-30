require 'highcore_sparkle'
require 'sparkle_formation'
require 'json'
require 'yaml'

class HighcoreSparkle

  include HighcoreSparkle::Options

  def self.load_library(sparkle, path)
    if File.directory?(path)
      sparkle.sparkle.add_sparkle(
          SparkleFormation::SparklePack.new(:root => path)
      )
    end
  end

  def self.load_requirements(sparkle, template)
    template[:requirements].each { |req|
      self.load_library(sparkle, Gem::Specification.find_by_name(req).gem_dir)
    } if template[:requirements]
  end

  def self.generate(template_path, template_name, stack_definition)
    template_definition = File.join(template_path, 'templates', "#{template_name}.yml")
    template = Options.symbolize_recursive(YAML.load_file(template_definition))
    template = Options.key_by_id_recursive(template)

    stack_input = JSON.parse(stack_definition, {:symbolize_names => true})
    components_input = stack_input.delete(:components)
    components = Options.generate_components(template, components_input, stack_input)

    root_pack = SparkleFormation::SparklePack.new(
        :root => template_path + '/pack'
    )

    # Load template
    sparkle = SparkleFormation.new(template_name,
                                   :sparkle => root_pack) do
      @outputs = {}

      #registry!(:description, template_name)

      components.each do |id, component|
        config = component[:config].clone.merge({:template => template_name})
        registry!(:"#{template_name}_#{component[:template_component]}", component[:id].to_sym, component, config)
      end

      registry!(:outputs, :outputs => @outputs)
    end
    self.load_requirements(sparkle, template)

    sparkle_parameters = SparkleFormation.new(:parameters, :sparkle => root_pack) do
      registry!(:parameters,
                :components => components,
                :compiled_template => sparkle.to_json
      )
    end
    self.load_requirements(sparkle_parameters, template)

    cfn_template = sparkle.compile.dump!.merge(sparkle_parameters.compile.dump!)
    MultiJson.dump(cfn_template)
  end
end
