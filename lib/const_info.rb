class Requirium::ConstInfo
  attr_accessor :mod, :sym, :error, :value

  def initialize(mod, sym)
    @mod, @sym, @cond, @mutex = mod, sym, ConditionVariable.new, Mutex.new
  end

  def has_value?
    !!(defined? @value)
  end

  def internal_load
    has, value = mod.send(:internal_load, sym)
    @value = value if has
    nil
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
end