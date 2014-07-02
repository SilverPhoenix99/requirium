require 'continuation'
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

  [:load, :require].each do |name|
    type = const_get("#{name.capitalize}Loader")
    define_method("auto#{name}", ->(*args) { add_loader type, args })
    define_method("auto#{name}_relative", ->(*args) do
      add_loader type, args, File.dirname(caller_locations(1, 1).first.path)
    end)
  end

  #def const_defined?(*args)
  #  Requirium.synchronize { super }
  #end

  def const_missing(sym)
    # if mri, use binding nesting
    nesting = nil
    if Requirium.mri?
      return unless nesting = caller_nesting
    end

    info = ConstInfo.new(self, sym, nesting)

    if Thread.current == Requirium.loader_thread
      # this avoids deadlocks. it uses the current loading to load the remaining dependencies
      has, value = internal_load(info)
      return has ? value : super
    end

    Requirium.queue.push(info)
    info.wait_ready
    raise info.error if info.error
    info.has_value? ? info.value : super
  end

  private

  def add_loader(type, args, dirname = nil)
    with_args(args) do |sym, paths|
      load_list { |l| l[sym.to_s] = type.new(sym, paths, dirname) }
    end
  end

  def caller_nesting
    cc = nil
    nst = nil
    count = 0

    t = Thread.current

    set_trace_func(lambda do |event, _, _, _, binding, _|
      if Thread.current == t
        if count == 2
          set_trace_func nil
          cc.call(nst = eval('Module.nesting', binding))
        elsif event == 'return'
          count += 1
        end
      end
    end)

    callcc { |cont| cc = cont } && nst
  end

  def internal_load(info)
    info.lookup_list.find do |klass|
      klass.send(:try_load, info.sym) if klass.singleton_class.include?(Requirium)
      return [true, klass.const_get(info.sym)] if klass.const_defined?(info.sym)
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

  def self.mri?
    (!defined?(RUBY_ENGINE) || RUBY_ENGINE == 'ruby') && RUBY_DESCRIPTION !~ /Enterprise/
  end
end
