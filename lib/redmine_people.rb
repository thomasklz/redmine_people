# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2017 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

require 'people_acl'
require 'redmine_activity_crm_fetcher'

Rails.configuration.to_prepare do
  require_dependency 'redmine_people/helpers/redmine_people'

  require_dependency 'acts_as_attachable_global/init'
  require_dependency 'redmine_people/patches/user_patch'
  require_dependency 'redmine_people/patches/application_helper_patch'
  require_dependency 'redmine_people/patches/users_controller_patch'
  require_dependency 'redmine_people/patches/my_controller_patch'
  require_dependency 'redmine_people/patches/calendar_patch'
  require_dependency 'redmine_people/patches/query_patch'
  require_dependency 'redmine_people/patches/mailer_patch'

  require_dependency 'redmine_people/hooks/views_layouts_hook'
  require_dependency 'redmine_people/hooks/views_my_account_hook'

  if Redmine::VERSION.to_s >= '3.4' || Redmine::VERSION::BRANCH != 'stable'
    require_dependency 'redmine_people/patches/query_filter_patch'
  end
end

module RedminePeople
  def self.available_permissions
    [:edit_people, :view_people, :add_people, :delete_people,
     :manage_departments,
     :manage_tags, :manage_public_people_queries, :edit_subordinates,
     :edit_announcement, :edit_work_experience, :edit_own_work_experience,
     :manage_calendar]
  end

  def self.settings() Setting[:plugin_redmine_people] end

  def self.users_acl() Setting.plugin_redmine_people[:users_acl] || {} end

  def self.default_list_style
    return 'list_excerpt'
  end

  def self.url_exists?(url)
    require_dependency 'open-uri'
    begin
      open(url)
      true
    rescue
      false
    end
  end

  def self.hide_age?
    Setting.plugin_redmine_people["hide_age"].to_i > 0
  end

  def self.contacts_plugin_with_select2?
    Redmine::Plugin.installed?(:redmine_contacts) && Redmine::Plugin.find(:redmine_contacts).version >= '4.0.8'
  end
end
