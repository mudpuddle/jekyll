module Jekyll
  module Hooks
    DEFAULT_PRIORITY = 20

    # compatibility layer for octopress-hooks users
    PRIORITY_MAP = {
      low: 10,
      normal: 20,
      high: 30,
    }.freeze

    # initial empty hooks
    @registry = {
      :site => {
        after_reset: [],
        post_read: [],
        pre_render: [],
        post_write: [],
      },
      :page => {
        post_init: [],
        pre_render: [],
        post_render: [],
        post_write: [],
      },
      :post => {
        post_init: [],
        pre_render: [],
        post_render: [],
        post_write: [],
      },
      :document => {
        pre_render: [],
        post_render: [],
        post_write: [],
      },
    }

    # map of all hooks and their priorities
    @hook_priority = {}

    NotAvailable = Class.new(RuntimeError)
    Uncallable = Class.new(RuntimeError)

    # register hook(s) to be called later, public API
    def self.register(owners, event, priority: DEFAULT_PRIORITY, &block)
      Array(owners).each do |owner|
        register_one(owner, event, priority_value(priority), &block)
      end
    end

    # Ensure the priority is a Fixnum
    def self.priority_value(priority)
      return priority if priority.is_a?(Fixnum)
      PRIORITY_MAP[priority] || DEFAULT_PRIORITY
    end

    # register a single hook to be called later, internal API
    def self.register_one(owner, event, priority, &block)
      unless @registry[owner]
        raise NotAvailable, "Hooks are only available for the following " <<
          "classes: #{@registry.keys.inspect}"
      end

      unless @registry[owner][event]
        raise NotAvailable, "Invalid hook. #{owner} supports only the " <<
          "following hooks #{@registry[owner].keys.inspect}"
      end

      unless block.respond_to? :call
        raise Uncallable, "Hooks must respond to :call"
      end

      insert_hook owner, event, priority, &block
    end

    def self.insert_hook(owner, event, priority, &block)
      @hook_priority[block] = "#{priority}.#{@hook_priority.size}".to_f
      @registry[owner][event] << block
    end

    # interface for Jekyll core components to trigger hooks
    def self.trigger(owner, event, *args)
      # proceed only if there are hooks to call
      return unless @registry[owner]
      return unless @registry[owner][event]

      # hooks to call for this owner and event
      hooks = @registry[owner][event]

      # sort and call hooks according to priority and load order
      hooks.sort_by { |h| @hook_priority[h] }.each do |hook|
        hook.call(*args)
      end
    end
  end
end
