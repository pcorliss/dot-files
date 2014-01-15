
begin
  # load wirble
  require 'rubygems'
  require 'wirble'

  # start wirble (with color)
  Wirble.init
  Wirble.colorize
rescue LoadError => err
  warn "Couldn't load Wirble: #{err}"
end

if ENV.include?('RAILS_ENV')

  def show_log
    change_log(STDOUT)
  end

  def hide_log
    change_log(nil)
  end

  def change_log(stream, colorize=true)
    require 'activerecord'
    ActiveRecord::Base.logger = ::Logger.new(stream)
    ActiveRecord::Base.clear_all_connections!
    ActiveRecord::Base.colorize_logging = colorize
  end

  if ENV['INLINE_LOGGING'] && !Object.const_defined?('RAILS_DEFAULT_LOGGER')
    require 'logger'
    Object.const_set('RAILS_DEFAULT_LOGGER', Logger.new(STDOUT))
  end
  
  def enable_factories
    require 'factory_girl'
    Factory.definition_file_paths = [
      Rails.root.join("test/factories"),
      Rails.root.join("spec/factories")
    ]
    Factory.find_definitions
  end

  #show_log

end

class Object
  def interest
    self.methods.sort - Object.methods
  end
end

def reload_working_set
  `git diff --name-only`.split("\n").each {|fn| load fn if fn.end_with?('.rb')}
end

def ops_config_load_path
  $LOAD_PATH << 'lib'
  require 'ops_config'
  require 'benchmark'
end

class Inspector
 
  # :nodoc:
  def self._collect_events_for_method_call(&block)
    events = []
    
    set_trace_func lambda { |event, file, line, id, binding, classname|
      events << { :event => event, :file => file, :line => line, :id => id, :binding => binding, :classname => classname }
    }
    
    begin
      yield
    ensure
      set_trace_func(nil)
    end

    events
  end

  # :nodoc:
  def self._trace_the_method_call(&block)
    events = _collect_events_for_method_call(&block)
    
    valid_event_types = ['call', 'c-call', 'return']
    
    events.each do |event|
      next unless valid_event_types.include?(event[:event])
      
      case event[:classname].to_s
        when 'ActiveRecord::Base'
          return events[-3]
        else
          return event if event[:event].include?('call')
      end
    end

  end

  def self.where_is_this_defined(&block)
    trace = _trace_the_method_call(&block)
    return "Unable to determine where the method was defined" unless trace

    if trace[:event] == 'c-call'
      "#{trace[:classname]} method :#{trace[:id]} defined in STDLIB"
    else
      "#{trace[:classname]} method :#{trace[:id]} defined in #{trace[:file]}:#{trace[:line]}"
    end
  end

end

