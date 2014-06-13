require 'thread'
require 'pathname'
require 'facets/string/snakecase'
require 'facets/module/home'
require 'facets/module/ancestor'

#Automatically calls <code>Kernel#load</code> or <code>Kernel#require</code> on first use.
#Example usage:
#
#    module M
#      extend Requirium
#
#      autoload :A
#      autoload :B, 'b', 'b1', 'b2'
#      autoload A: nil, B: ['b', 'b1', 'b2']
#      autoload_relative :X
#      autoload_relative :Y, 'y', 'y1', 'y2'
#      autoload_relative X: nil, Y: ['y', 'y1', 'y2']
#
#      autorequire :A
#      autorequire :B, 'b', 'b1', 'b2'
#      autorequire A: nil, B: ['b', 'b1', 'b2']
#      autorequire_relative :X
#      autorequire_relative :Y, 'y', 'y1', 'y2'
#      autorequire_relative X: nil, Y: ['y', 'y1', 'y2']
#    end
module Requirium
  VERSION = '0.0.2'.freeze

  class Info
    attr_accessor :sym
    attr_accessor :mod
    attr_reader :cond, :mutex

    def initialize(mod, sym)
      @mod, @sym, @cond, @mutex = mod, sym, ConditionVariable.new, Mutex.new
    end

    def internal_load
      self.sym = mod.send(:internal_load, sym)
    end

    def ready!
      @ready = true
      mutex.synchronize { cond.signal }
      nil
    end

    def wait_ready
      mutex.synchronize { until @ready; cond.wait(mutex) end }
      nil
    end
  end

  @queue = Queue.new
  @loader_thread = Thread.new do
      loop do
        info = @queue.pop
        begin
          info.internal_load
        rescue ScriptError => e
          $stderr.puts e
        rescue => e
          $stderr.puts e
        ensure
          info.ready!
        end
      end
  end

  class << self
    attr_reader :loader_thread, :queue
  end

  def autoload(*args) #TODO sync const_defined? ?
    common_auto :load, args
  end

  def autoload_relative(*args) #TODO sync const_defined? ?
    common_auto :load, args, File.dirname(caller(1, 1)[0][/^(.+):\d+:in `.+'$/, 1])
  end

  def autorequire(*args) #TODO sync const_defined? ?
    common_auto :require, args
  end

  def autorequire_relative(*args) #TODO sync const_defined? ?
    common_auto :require, args, File.dirname(caller(1, 1)[0][/^(.+):\d+:in `.+'$/, 1])
  end

  #def const_defined?(*args)
  #  Requirium.synchronize { super }
  #end

  def const_missing(sym)
    return internal_load(sym) if Thread.current == Requirium.loader_thread

    Requirium.queue.push(info = Info.new(self, sym))
    info.wait_ready
    const_defined?(sym) ? info.sym : super
  end

  private

  def common_auto(method, args, dirname = nil)
    if args.length == 1 && args.first.is_a?(Hash)
      args.first.each { |sym, paths| add_load_item method, sym, paths, dirname }
      return
    end

    sym, paths = args
    add_load_item method, sym, paths, dirname
  end

  def add_load_item(method, sym, paths, dirname)
    return if const_defined?(sym)

    paths = clean_paths(method, sym, paths, dirname)

    #puts "auto#{method}#{dirname ? '_relative' : ''} #{sym.inspect}, #{paths.map(&:inspect).join(', ')}"
    load_list { |l| l[sym.to_s] = [method, paths] }
    nil
  end

  def clean_paths(method, sym, paths, dirname)
    paths = [*paths]
    paths = [sym.to_s.snakecase] if paths.empty?

    if dirname
      dirname = Pathname(dirname)
      paths.map! { |path| (dirname + path).to_s }
    end

    # append possible suffix
    paths.map! { |p| Dir[*Gem.suffixes.map { |e| p + e }].first }.compact! if method == :load

    paths
  end

  def internal_load(sym)
    return const_get(sym) if const_defined?(sym)
    str_sym = sym.to_s
    has_sym, method, paths = load_list { |l| [l.has_key?(str_sym), *l[str_sym]] }

    return parent.const_missing(sym) unless has_sym # go to parent

    raise NoMethodError, "invalid method type: #{method.inspect}" unless [:load, :require].include?(method)

    paths.each do |filename|
      #puts "#{method} #{sym.inspect}, #{filename.inspect}"
      send(method, filename)
    end

    if const_defined?(sym)
      load_list { |l| l.delete(sym.to_s) }
      const_get(sym)
    end
  end

  def load_list
    @mutex ||= Mutex.new
    @load_list ||= {}
    @mutex.synchronize { yield(@load_list) }
  end

  def parent
    name.split('::')[0..-2].inject(Object) { |mod, name| mod.const_get(name) }
  end
end
