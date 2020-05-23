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
      def before_action(*args)
        set_callback :action, :before, *args
      end
      def after_action(*args)
        set_callback :action, :after, *args
      end
      def around_action(*args)
        set_callback :action, :around, *args
      end
    end
  end
end
