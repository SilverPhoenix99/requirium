module Requirium
  class RequireLoader
    attr_reader :sym

    def initialize(sym, paths, dirname = nil)
      @sym = sym
      @paths = clean_paths(paths, dirname)
    end

    def call(mod)
      @paths.each { |filename| mod.send(method, filename) }
      nil
    end

    private

    def clean_paths(paths, dirname)
      paths = [*paths]
      paths = [sym.to_s.snakecase] if paths.empty?

      if dirname
        dirname = Pathname(dirname)
        paths.map! { |path| (dirname + path).to_s }
      end

      paths
    end

    def method
      :require
    end
  end
end