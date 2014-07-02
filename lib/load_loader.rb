require_relative 'require_loader'

module Requirium
  class LoadLoader < RequireLoader

    private

    def clean_paths(paths, dirname)
      paths = super

      # append possible suffix
      paths.map! { |p| Dir[*Gem.suffixes.map { |e| p + e }].first }.compact!

      paths
    end

    def method
      :load
    end
  end
end