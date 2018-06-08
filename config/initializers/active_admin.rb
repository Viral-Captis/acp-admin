ActiveAdmin.setup do |config|

  # == Site Title
  #
  # Set the title that is displayed on the main layout
  # for each of the active admin pages.
  #
  config.site_title = ->(view) { Current.acp.name }
  config.root_to = 'dashboard#index'

  # Set an optional image to be displayed for the header
  # instead of a string (overrides :site_title)
  #
  # Note: Aim for an image that's 21px high so it fits in the header.
  #
  # config.site_title_image = 'logo.png'

  config.default_namespace = false
  config.authentication_method = :authenticate_admin!
  config.current_user_method = :current_admin

  # == User Authorization
  #
  # Active Admin will automatically call an authorization
  # method in a before filter of all controller actions to
  # ensure that there is a user with proper rights. You can use
  # CanCanAdapter or make your own. Please refer to documentation.
  config.authorization_adapter = ActiveAdmin::CanCanAdapter

  # You can customize your CanCan Ability class name here.
  config.cancan_ability_class = 'Ability'

  # You can specify a method to be called on unauthorized access.
  # This is necessary in order to prevent a redirect loop which happens
  # because, by default, user gets redirected to Dashboard. If user
  # doesn't have access to Dashboard, he'll end up in a redirect loop.
  # Method provided here should be defined in application_controller.rb.
  config.on_unauthorized_access = :access_denied

  # == Logging Out
  #
  # Active Admin displays a logout link on each screen. These
  # settings configure the location and method used for the link.
  #
  # This setting changes the path where the link points to. If it's
  # a string, the strings is used as the path. If it's a Symbol, we
  # will call the method to return the path.
  #
  # Default:
  config.logout_link_path = :destroy_admin_session_path

  # This setting changes the http method used when rendering the
  # link. For example :get, :delete, :put, etc..
  #
  # Default:
  # config.logout_link_method = :get

  # == Admin Comments
  #
  # This allows your users to comment on any resource registered with Active Admin.
  #
  # You can completely disable comments:
  config.comments = false
  #
  # You can change the name under which comments are registered:
  # config.comments_registration_name = 'AdminComment'

  # == Batch Actions
  #
  # Enable and disable Batch Actions
  #
  config.batch_actions = false


  # == Controller Filters
  #
  # You can add before, after and around filters to all of your
  # Active Admin resources and pages from here.
  #
  # config.before_action :do_something_awesome
  config.before_action :set_locale

  # == Setting a Favicon
  #
  # config.favicon = '/assets/favicon.ico'


  # == Removing Breadcrumbs
  #
  # Breadcrumbs are enabled by default. You can customize them for individual
  # resources or you can disable them globally from here.
  #
  config.breadcrumb = false


  # == Register Stylesheets & Javascripts
  #
  # We recommend using the built in Active Admin layout and loading
  # up your own stylesheets / javascripts to customize the look
  # and feel.
  #
  # To load a stylesheet:
  #   config.register_stylesheet 'my_stylesheet.css'
  #
  # You can provide an options hash for more control, which is passed along to stylesheet_link_tag():
  #   config.register_stylesheet 'my_print_stylesheet.css', :media => :print
  #
  # To load a javascript file:
  #   config.register_javascript 'my_javascript.js'


  # == CSV options
  #
  # Set the CSV builder separator
  # config.csv_options = { :col_sep => ';' }
  #
  # Force the use of quotes
  # config.csv_options = { :force_quotes => true }

  # Fix encoding issue with Excel 2003 https://stackoverflow.com/questions/155097/microsoft-excel-mangles-diacritics-in-csv-files
  config.csv_options = { byte_order_mark: "\xEF\xBB\xBF" }

  # == Menu System
  #
  # You can add a navigation menu to be used in your application, or configure a provided menu
  #
  # To change the default utility navigation to show a link to your website & a logout btn
  #
  #   config.namespace :admin do |admin|
  #     admin.build_menu :utility_navigation do |menu|
  #       menu.add label: "My Great Website", url: "http://www.mygreatwebsite.com", html_options: { target: :blank }
  #       admin.add_logout_button_to_menu menu
  #     end
  #   end
  #
  # If you wanted to add a static menu item to the default menu provided:
  #
  config.namespace false do |admin|
    admin.build_menu do |menu|
      menu.add label: :halfdays_human_name, priority: 6
      menu.add label: -> { I18n.t('active_admin.menu.billing') }, priority: 7, id: :billing
      menu.add label: -> { I18n.t('active_admin.menu.other') }, priority: 8, id: :other
    end
  end

  # == Download Links
  #
  # You can disable download links on resource listing pages,
  # or customize the formats shown per namespace/globally
  #
  # To disable/customize for the :admin namespace:
  #
  # config.namespace :admin do |admin|
    # # Disable the links entirely
    # # admin.download_links = false

    config.download_links = [:csv]

    #  # Enable/disable the links based on block
    #  #   (for example, with cancan)
    #  admin.download_links = proc { can?(:view_download_links) }
  # end

  # == Pagination
  #
  # Pagination is enabled by default for all resources.
  # You can control the default per page count for all resources here.
  #
  # config.default_per_page = 30

  # == Filters
  #
  # By default the index screen includes a “Filters” sidebar on the right
  # hand side with a filter for each attribute of the registered model.
  # You can enable or disable them for all resources here.
  #
  # config.filters = true

  config.current_filters = false

  # Streaming is causing issue with apartment DB schema.
  config.disable_streaming_in = %w[production development test]
end

module ActiveAdmin::ViewHelpers
  include ApplicationHelper
  include MembershipsHelper
  include DashboardHelper
  include HalfdaysHelper
  include InvoicesHelper
  include AcpsHelper
end

class ActiveAdmin::ResourceController
  include ApplicationHelper
  include AcpsHelper
  include FormsHelper

  def csv_filename
    "#{resource_class.model_name.human(count: 2).downcase.dasherize.delete(' ')}-#{Time.zone.now.to_date.to_s(:default)}.csv"
  end
end

# Ensure that the overwritten HalfdayNaming.i18n_key is used
class ActiveAdmin::Resource::Name
  def i18n_key
    @klass&.model_name&.i18n_key || super
  end
end

module ActiveAdmin
  module Views
    module Pages
      class Base < Arbre::HTML::Document
        def build(*args)
          super
          add_classes_to_body
          add_data_attributes_to_body
          build_active_admin_head
          build_page
        end

        private

        def add_data_attributes_to_body
          @body.set_attribute('data-locale', I18n.locale)
        end
      end
    end
  end
end
