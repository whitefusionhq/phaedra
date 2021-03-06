require "active_support/callbacks"
require "active_support/concern"

module Phaedra
  module CallbacksActionable
    extend ActiveSupport::Concern
    include ActiveSupport::Callbacks

    included do
      define_callbacks :action
    end

    module ClassMethods
      def before_action(*args, &block)
        set_callback :action, :before, *args, &block
      end
      def after_action(*args, &block)
        set_callback :action, :after, *args, &block
      end
      def around_action(*args, &block)
        set_callback :action, :around, *args, &block
      end
    end
  end
end
