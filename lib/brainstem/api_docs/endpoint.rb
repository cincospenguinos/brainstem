require 'brainstem/concerns/optional'
require 'active_support/core_ext/string/inflections'
require 'brainstem/concerns/formattable'
require 'forwardable'
require 'pathname'

#
# Per-endpoint holder for presenter and controller information.
#
module Brainstem
  module ApiDocs
    class Endpoint
      extend Forwardable
      include Concerns::Optional
      include Concerns::Formattable

      ACTION_ORDER = %w(index show create update delete)

      def valid_options
        super | [
          :path,
          :http_methods,
          :controller,
          :controller_name,
          :action,
          :presenter
        ]
      end


      def initialize(atlas, options = {})
        self.atlas = atlas
        super options
        yield self if block_given?
      end


      attr_accessor :path,
                    :http_methods,
                    :controller,
                    :controller_name,
                    :action,
                    :atlas


      #
      # Pretty prints each endpoint.
      #
      def to_s
        "#{http_methods.join(" / ")} #{path}"
      end


      #
      # Merges http methods (for de-duping Rails' routes).
      #
      def merge_http_methods!(methods)
        self.http_methods |= methods
      end


      #
      # Sorts this endpoint in comparison to other endpoints.
      #
      # Follows a manually defined order of precedence (+ACTION_ORDER+). The
      # earlier an action name appears on the list, the earlier it is sorted.
      #
      # In the event that an action is not on the list, it is sorted after any
      # listed routes, and then sorted alphabetically among the remainder.
      #
      def <=>(other)

        # Any unordered routes are assigned an index of +ACTION_ORDER.count+.
        ordered_actions_count = ACTION_ORDER.count
        own_action_priority     = ACTION_ORDER.index(action.to_s)       || ordered_actions_count
        other_action_priority   = ACTION_ORDER.index(other.action.to_s) || ordered_actions_count

        # If the priorities are unequal (i.e. one or both are named; duplicates
        # should not exist for named routes):
        if own_action_priority != other_action_priority

          # Flip order if this action's priority is greater than the other.
          # other_action_priority <=> own_action_priority
          own_action_priority <=> other_action_priority

        # If the priorities are equal, i.e. both not in the list:
        else

          # Flip order if this action's name is alphabetically later.
          action.to_s <=> other.action.to_s
        end
      end


      ################################################################################
      # Derived fields
      ################################################################################

      #
      # Is the entire endpoint undocumentable?
      #
      def nodoc?
        action_configuration[:nodoc]
      end


      def title
        @title ||= contextual_documentation(:title) || action.to_s.humanize
      end


      def description
        @description ||= contextual_documentation(:description) || ""
      end


      def valid_params
        @valid_params ||= key_with_default_fallback(:valid_params)
      end


      #
      # Returns a hash of all root-level params with values of an array of
      # the parameters nested underneath, or +nil+ in the event they are
      # root-level non-nested params.
      #
      # @return [Hash{Symbol => Array,NilClass}] root keys and the keys
      #   nested under them, or nil if not a nested param.
      #
      def root_param_keys
        @root_param_keys ||= begin
          valid_params.to_h
            .inject({}) do |hsh, (field_name, data)|
              next hsh if data[:nodoc]

              if data.has_key?(:root)
                key  = data[:root].respond_to?(:call) ? data[:root].call(controller.const) : data[:root]
                (hsh[key] ||= []) << field_name
              else
                hsh[field_name] = nil
              end

              hsh
            end
        end
      end


      #
      # Retrieves the +presents+ settings.
      #
      def valid_presents
        key_with_default_fallback(:presents) || {}
      end


      #
      # Used to retrieve this endpoint's presenter constant.
      #
      def declared_presented_class
        valid_presents.has_key?(:target_class) &&
          !valid_presents[:nodoc] &&
          valid_presents[:target_class]
      end


      #
      # Stores the +ApiDocs::Presenter+ object associated with this endpoint.
      #
      attr_accessor :presenter


      ################################################################################
      # Configuration Helpers
      #################################################################################

      #
      # Helper for retrieving configuration from its controller.
      #
      delegate :configuration => :controller
      delegate :find_by_class => :atlas


      #
      # Helper for retrieving action-specific configuration from the controller.
      #
      def action_configuration
        configuration[action] || {}
      end


      #
      # Retrieves default action context from the controller.
      #
      def default_configuration
        configuration[:_default] || {}
      end


      #
      # Returns a key if it exists and is documentable
      #
      def contextual_documentation(key)
        action_configuration.has_key?(key) &&
          !action_configuration[key][:nodoc] &&
          action_configuration[key][:info]
      end


      def key_with_default_fallback(key)
        action_configuration[key] || default_configuration[key]
      end


      def presenter_title
        presenter && presenter.title
      end


      #
      # Returns the relative path from this endpoint's controller to this
      # endpoint's declared presenter.
      #
      def relative_presenter_path_from_controller(format)
        if presenter && controller
          controller_path = Pathname.new(File.dirname(controller.suggested_filename_link(format)))
          presenter_path  = Pathname.new(presenter.suggested_filename_link(format))

          presenter_path.relative_path_from(controller_path).to_s
        end
      end
    end
  end
end