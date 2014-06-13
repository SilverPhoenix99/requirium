require_relative 'lib/version'

Gem::Specification.new do |s|
  s.name          = 'requirium'
  s.version       = Requirium::VERSION
  s.summary       = 'An autoload alternative'
  s.description   = 'An autoload alternative'
  s.license       = 'MIT'
  s.authors       = %w'SilverPhoenix99'
  s.email         = %w'silver.phoenix99@gmail.com'
  s.homepage      = 'https://github.com/SilverPhoenix99/requirium'
  s.require_paths = %w'lib'
  s.files         = Dir['{lib/**/*.rb,*.md}']
  s.add_dependency 'facets', '~> 2.9'
  s.post_install_message = <<-eos
+----------------------------------------------------------------------------+
  Thank you for choosing Requirium.

  ==========================================================================
  If you find any bugs, please report them on
    https://github.com/SilverPhoenix99/requirium/issues

+----------------------------------------------------------------------------+
  eos
end