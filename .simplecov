# .simplecov
SimpleCov.start 'rails' do
  add_filter '/bin/'
  add_filter '/db/'
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Serializers', 'app/serializers'
  
  # Set minimum coverage percentage
  minimum_coverage 90
  
  # Use HTML formatter
  formatter SimpleCov::Formatter::HTMLFormatter
end
