module Phaedra
  module Initializers
    Registration = Struct.new(
      :origin,
      :priority,
      :block,
      keyword_init: true
    ) do
      def to_s
        "#{owner}:#{priority} for #{block}"
      end
    end

    DEFAULT_PRIORITY = 20

    PRIORITY_MAP = {
      low: 10,
      normal: 20,
      high: 30,
    }.freeze

    # initial empty hooks
    @registry = []

    NotAvailable = Class.new(RuntimeError)
    Uncallable = Class.new(RuntimeError)

    # Ensure the priority is a Fixnum
    def self.priority_value(priority)
      return priority if priority.is_a?(Integer)

      PRIORITY_MAP[priority] || DEFAULT_PRIORITY
    end

    def self.register(origin, priority: DEFAULT_PRIORITY, &block)
      raise Uncallable, "Initializers must respond to :call" unless block.respond_to? :call

      @registry << Registration.new(
        origin: origin,
        priority: priority_value(priority),
        block: block
      )

      block
    end

    def self.remove(origin)
      @registry.delete_if { |item| item.origin == origin }
    end

    def self.run(force: false)
      if !@initializers_ran || force
        prioritized_initializers.each do |initializer|
          initializer.block.call
        end
      end

      @initializers_ran = true
    end

    def self.prioritized_initializers
      # sort initializers according to priority and load order
      grouped_initializers = @registry.group_by(&:priority)
      grouped_initializers.keys.sort.reverse.map do |priority|
        grouped_initializers[priority]
      end.flatten
    end
  end
end
