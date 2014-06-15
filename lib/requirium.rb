require 'thread'
require 'pathname'
require 'facets/string/snakecase'
require 'facets/module/home'
require 'facets/module/ancestor'

require_relative 'version'
require_relative 'const_info'
require_relative 'require_loader'
require_relative 'load_loader'

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
  @queue = Queue.new
  @loader_thread = Thread.new do
      loop do
        info = @queue.pop
        begin
          info.internal_load
        rescue ScriptError => e
          info.error = e
        rescue => e
          info.error = e
        ensure
          info.ready!
        end
      end
  end

  class << self
    attr_reader :loader_thread, :queue
  end

  def autoload(*args)
    add_loader LoadLoader, args
  end

  def autoload_relative(*args)
    add_loader LoadLoader, args, File.dirname(caller(1, 1)[0][/^(.+):\d+:in `.+'$/, 1])
  end

  def autorequire(*args)
    add_loader RequireLoader, args
  end

  def autorequire_relative(*args)
    add_loader RequireLoader, args, File.dirname(caller(1, 1)[0][/^(.+):\d+:in `.+'$/, 1])
  end

  #def const_defined?(*args)
  #  Requirium.synchronize { super }
  #end

  def const_missing(sym)
    if Thread.current == Requirium.loader_thread
      # this avoids deadlocks. it uses the current loading to load the remaining dependencies
      has, value = internal_load(sym)
      return has ? value : super
    end

    Requirium.queue.push(info = ConstInfo.new(self, sym))
    info.wait_ready
    raise info.error if info.error
    info.has_value? ? info.value : super
  end

  private

  def add_loader(method, args, dirname = nil)
    with_args(args) do |sym, paths|
      load_list { |l| l[sym.to_s] = method.new(sym, paths, dirname) }
    end
  end

  def internal_load(sym)
    lookup_list.find do |klass|
      klass.send(:try_load, sym) if klass.singleton_class.include?(Requirium)
      return [true, klass.const_get(sym)] if klass.const_defined?(sym)
    end

    [false, nil]
  end

  def load_list
    @mutex ||= Mutex.new
    @load_list ||= {}
    @mutex.synchronize { yield(@load_list) }
  end

  def try_load(sym)
    str_sym = sym.to_s
    loader = load_list { |l| l[str_sym] }
    return unless loader
    loader.call(self)
    load_list { |l| l.delete(sym.to_s) }
    nil
  end

  def with_args(args)
    if args.length == 1 && args.first.is_a?(Hash)
      args.first.each do |sym, paths|
        next if const_defined?(sym)
        yield sym, paths
      end
    elsif !const_defined?(args.first)
      yield args.first, args[1..-1]
    end

    nil
  end

  def lookup_list
    list = name.split('::').reduce([Object]) { |a, n| a << a.last.const_get(n) }.reverse!
    list.push(*ancestors)
    list.uniq!
    list
  end

end
