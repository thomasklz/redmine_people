# encoding: utf-8
#
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

module PeopleHelper

  def people_tabs(person)
    tabs = []
    tabs << {:name => 'activity', :partial => 'activity', :label => l(:label_activity)}
    tabs << {:name => 'files', :partial => 'attachments', :label => l(:label_attachment_plural)}
    tabs << {:name => 'projects', :partial => 'projects', :label => l(:label_project_plural)}
    tabs << {:name => 'subordinates', :partial => 'subordinates', :label => l(:label_people_subordinates)} if person.subordinates.any?
    tabs
  end

  def birthday_date(person)
    ages = person_age(person.age)
    if person.birthday.day == Date.today.day && person.birthday.month == Date.today.month
       "#{l(:label_today).capitalize} #{ages}"
    else
      "#{person.birthday.day} #{t('date.month_names')[person.birthday.month]} #{ages}"
    end
  end

  def person_manager_full_name
    manager = @person.manager_id ? Person.find(@person.manager_id) : ''
    content_tag('span', manager, :class => 'manager')
  end

  def retrieve_people_query
    if params[:query_id].present?
      @query = PeopleQuery.find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      session[:people_query] = {:id => @query.id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:people_query].nil?
      # Give it a name, required to be valid
      @query = PeopleQuery.new(:name => "_")
      @query.build_from_params(params)
      session[:people_query] = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = PeopleQuery.find(session[:people_query][:id]) if session[:people_query][:id]
      @query ||= PeopleQuery.new(:name => "_", :filters => session[:people_query][:filters], :group_by => session[:people_query][:group_by], :column_names => session[:people_query][:column_names])
    end
  end

  def people_list_style
    list_styles = people_list_styles_for_select.map(&:last)
    if params[:people_list_style].blank?
      list_style = list_styles.include?(session[:people_list_style]) ? session[:people_list_style] : RedminePeople.default_list_style
    else
      list_style = list_styles.include?(params[:people_list_style]) ? params[:people_list_style] : RedminePeople.default_list_style
    end
    session[:people_list_style] = list_style
  end

  def people_list_styles_for_select
    list_styles = [[l(:label_people_list_excerpt), "list_excerpt"]]
  end

  def people_principals_check_box_tags(name, principals)
    s = ''
    principals.each do |principal|
      s << "<label>#{ check_box_tag name, principal.id, false, :id => nil } #{principal.is_a?(Group) ? l(:label_group) + ': ' + principal.to_s : principal}</label>\n"
    end
    s.html_safe
  end

  def people_principals_radio_button_tags(name, principals)
    s = ''
    principals.each do |principal|
      s << "<label>#{ radio_button_tag name, principal.id, false, :id => nil } #{principal.is_a?(Group) ? l(:label_group) + ': ' + principal.to_s : principal}</label>\n"
    end
    s.html_safe
  end

  def change_status_link(person)
    return unless User.current.allowed_people_to?(:edit_people, person) && person.id != User.current.id && !person.admin
    url = {:controller => 'people', :action => 'update', :id => person, :page => params[:page], :status => params[:status], :tab => nil}

    if person.locked?
      link_to l(:button_unlock), url.merge(:person => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif person.registered?
      link_to l(:button_activate), url.merge(:person => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif person != User.current
      link_to l(:button_lock), url.merge(:person => {:status => User::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    end
  end

  def person_tag(person, options={})
    avatar_size = options.delete(:size) || 16
    if person.visible? && !options[:no_link]
      person_avatar = link_to(avatar(person, :size => avatar_size), person_path(person), :id => "avatar")
      person_name = link_to(person.name, person_path(person))
    else
      person_avatar = avatar(person, :size => avatar_size)
      person_name = person.name
    end

    case options.delete(:type).to_s
    when "avatar"
      person_avatar.html_safe
    when "plain"
      person_name.html_safe
    else
      content_tag(:span, "#{person_avatar} #{person_name}".html_safe, :class => "person")
    end
  end

  def render_people_tabs(tabs)
    if tabs.any?
      render :partial => 'common/people_tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end

  def cleaned_phone(phone)
    phone.scan(/[\d+()-]+/).join
  end

  def select_people_manager_tag(name, option_tags, options={})
    id = {:id => options[:id] || "new"}
    select_options = options[:select_options] || {}
    s = ''
    s << select_tag(name, option_tags, select_options)
    s << javascript_tag("$('#person_information_attributes_manager_id').select2({
          ajax: {
            url: '#{autocomplete_for_manager_person_path(id)}',
            dataType: 'json',
            delay: 250,
            data: function (params) {
              return { q: params.term };
            },
            processResults: function (data, params) {
              return { results: data };
            },
            cache: true
          },
          placeholder: ' ',
          allowClear: true,
          minimumInputLength: 1,
          width: '60%',
          templateResult: formatState
        }).on('select2:open', function (e) {
          $('.select2-search__field').val(' ').trigger($.Event('input', { which: 13 })).val('');
        });
        function formatState (opt) {
          var $opt = $('<span>' + opt.avatar + '&nbsp;' + opt.text + '</span>');
          return $opt;
        };")

    s.html_safe
  end
end
