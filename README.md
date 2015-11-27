Highcore sparkle adapter

Call template generator as shown below
```ruby
#!/usr/bin/env ruby

require 'highcore_sparkle'
require 'trollop'

options = Trollop::options do
  opt :stack_definition, 'JSON-encoded stack definition', :type => :string, :required => true
  opt :template, 'Name of the stack template', :type => :string, :required => true
  opt :template_path, 'Path to the template directory', :type => :string, :default => Dir.pwd
end            

HighcoreSparkle::generate(template_path, template, stack_definition)
```
