class Requirium::ConstInfo
  attr_accessor :mod, :sym

  def initialize(mod, sym)
    @mod, @sym, @cond, @mutex = mod, sym, ConditionVariable.new, Mutex.new
  end

  def internal_load
    mod.send(:internal_load, sym)
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