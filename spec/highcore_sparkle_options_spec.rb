require 'highcore_sparkle/highcore_sparkle'

RSpec.describe HighcoreSparkle, '#options' do

  context 'with a template containing components' do
    template = {
        'components' => [
            {'id' => 'test-api', 'parameters' => [{'id' => 'instance_type', 'type' => 'string'}]},
            {'id' => 'test-ui', 'parameters' => [{'id' => 'instance_type', 'type' => 'string'}]}
        ]
    }
    template_clone = template.clone

    it 'converts string keys to symbols recursively' do
      symbolized_template = HighcoreSparkle::Options.symbolize_recursive(template)
      expect(symbolized_template.keys.first).to be_a Symbol
      expect(symbolized_template).to include :components
      expect(symbolized_template[:components]).to include ({:id => 'test-api', :parameters => [{:id => 'instance_type', :type => 'string'}]})
    end

    context 'with a symbolized template' do
      symbolized_template = HighcoreSparkle::Options.symbolize_recursive(template)
      symbolized_template_clone = symbolized_template.clone

      it 'converts a structure to a hash using id values as keys' do
        keyed_template = HighcoreSparkle::Options.key_by_id_recursive(symbolized_template)
        expect(keyed_template.keys.first).to be_a Symbol
        expect(keyed_template).to include :components
        expect(keyed_template[:components]).to include :'test-api' => {:id => 'test-api', :parameters => {:instance_type => {:id => 'instance_type', :type => 'string'}}}
      end

      context 'with a keyed template' do
        keyed_template = HighcoreSparkle::Options.key_by_id_recursive(symbolized_template)
        keyed_template_clone = keyed_template.clone

        it 'unifies component keys along with IDs' do
          unified_components = HighcoreSparkle::Options.unify_components_ids(keyed_template[:components])
          expect(unified_components).to include :testapi
          expect(unified_components[:testapi]).to include :id => 'testapi'
        end

        context 'with components and stack parameters' do
          components = {
              :'test-api1'=>{
                  :id=>'test-api1',
                  :template_component=>'test-api',
                  :parameters=>{:instance_type=>{:id=>'instance_type', :value=>'t2.micro'}}},
              :'test-ui1'=>{
                  :id=>'test-ui1',
                  :template_component=>'test-ui',
                  :parameters=>{:instance_type=>{:id=>'instance_type', :value=>'t2.medium'}},
                  :components=>{:api1=>{:id=>'test-api1', :template_component=>'test-api'}}}}
          parameters = {
              :vpc_id=>{:id=>'vpc_id', :value=>'vpc-11111111'},
              :subnet_ids=>{:id=>'subnet_ids', :value=>['subnet-11111111', 'subnet-22222222', 'subnet-33333333']}}
          components_clone = components.clone
          parameters_clone = parameters.clone

          it 'generates components structure' do
            generated_components = HighcoreSparkle::Options.generate_components(keyed_template, components, parameters)

            expect(generated_components).to include :testapi1, :testui1
            expect(generated_components[:testapi1]).to include :id, :template_component, :parameters, :config, :components
            expect(generated_components[:testui1]).to include :id, :template_component, :parameters, :config, :components
            expect(generated_components[:testapi1][:config]).to include :vpc_id, :instance_type
            expect(generated_components[:testapi1][:config][:vpc_id]).to eq 'vpc-11111111'
            expect(generated_components[:testapi1][:parameters]).to include :vpc_id, :instance_type
            expect(generated_components[:testapi1][:parameters][:vpc_id]).to be_a Hash
          end

          it 'keeps the context intact' do
            expect(template).to eq template_clone
            expect(symbolized_template).to eq symbolized_template_clone
            expect(keyed_template).to eq keyed_template_clone
            expect(components).to eq components_clone
            expect(parameters).to eq parameters_clone
          end
        end
      end
    end
  end

  context 'with a boolean option' do
    option = {:value => 'true', :type => 'bool'}

    it 'casts "true" or "false" to bool' do
      HighcoreSparkle::Options.calculate_value!(option)
      expect(option[:value]).to eq true
      expect(!!option[:value]).to eq option[:value]
      option[:value] = 'false'
      HighcoreSparkle::Options.calculate_value!(option)
      expect(option[:value]).to eq false
      expect(!!option[:value]).to eq option[:value]
    end
  end

  context 'with a json option' do
    option = {:value => '[{"key1": "value1"}]', :type => 'json'}

    it 'parses json' do
      HighcoreSparkle::Options.calculate_value!(option)
      expect(option).to include :value
      expect(option[:value]).to be_a Array
      expect(option[:value]).to include 'key1' => 'value1'
    end
  end

  context 'with an array option' do
    option = {:value => 'value1,value2', :type => 'array'}

    it 'converts comma-separated string to array' do
      HighcoreSparkle::Options.calculate_value!(option)
      expect(option).to include :value
      expect(option[:value]).to be_a Array
      expect(option[:value]).to include 'value1', 'value2'
    end
  end

  context 'with an option with default and value' do
    option = {:value => 1, :default => 2, :type => 'int'}

    it 'prefers value over default' do
      HighcoreSparkle::Options.calculate_value!(option)
      expect(option).to include :value
      expect(option[:value]).to eq 1
    end
  end

  context 'with an option with default and without value' do
    option = {:default => 2, :type => 'int'}

    it 'sets value to default' do
      HighcoreSparkle::Options.calculate_value!(option)
      expect(option).to include :value
      expect(option[:value]).to eq 2
    end
  end
end




