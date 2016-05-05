require 'brainstem/concerns/lookup'

module Brainstem
  module DSL
    class Association
      include Brainstem::Concerns::Lookup

      attr_reader :name, :target_class, :description, :options

      def initialize(name, target_class, description, options)
        @name = name.to_s
        @target_class = target_class
        @description = description
        @options = options
      end

      def method_name
        if options[:dynamic] || options[:lookup]
          nil
        else
          (options[:via].presence || name).to_s
        end
      end

      def run_on(model, context, helper_instance = Object.new)
        if options[:dynamic] && (!options[:lookup] || context[:models].size == 1)
          proc = options[:dynamic]
          if proc.arity == 1
            helper_instance.instance_exec(model, &proc)
          else
            helper_instance.instance_exec(&proc)
          end
        elsif options[:lookup]
          run_on_with_lookup(model, context, helper_instance)
        else
          model.send(method_name)
        end
      end

      def polymorphic?
        target_class == :polymorphic
      end

      def always_return_ref_with_sti_base?
        options[:always_return_ref_with_sti_base]
      end
    end
  end
end
