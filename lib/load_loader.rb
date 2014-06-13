require_relative 'require_loader'

class Requirium::LoadLoader < Requirium::RequireLoader

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