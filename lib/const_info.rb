module Requirium
  class ConstInfo
    attr_accessor :mod, :sym, :nesting, :error, :value

    def initialize(mod, sym, nesting)
      @mod, @sym, @nesting, @cond, @mutex = mod, sym, nesting, ConditionVariable.new, Mutex.new
    end

    def has_value?
      !!(defined? @value)
    end

    def internal_load
      has, value = mod.send(:internal_load, self)
      @value = value if has
      nil
    end

    def lookup_list
      return @nesting | @mod.ancestors if @nesting # always returns for mri

      # hacky fallback for jruby, rubinius, etc...

      # singleton classes don't have a name, but the base class is the first from the ancestors

      case
        # usual class
        when @mod.name
          split(@mod.name) | @mod.ancestors

        # singleton
        when @mod.ancestors.first != @mod
          mod = ObjectSpace.each_object(@mod).first
          split(mod.name) | mod.ancestors

        # anonymous class
        else
          mod.ancestors
      end

    end

    def ready!
      @ready = true
      @mutex.synchronize { @cond.signal }
      nil
    end

    def wait_ready
      @mutex.synchronize { until @ready; @cond.wait(@mutex) end }
      nil
    end

    private

    def split(name)
      return [] unless name
      name.split('::').reduce([]) { |a, n| a << (a.last || Object).const_get(n) }.reverse!
    end
  end
end