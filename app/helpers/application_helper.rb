module ApplicationHelper
  def active_admin_nav_class(controller_path)
    return 'active' if params[:controller] == controller_path
    return 'active' if params[:controller].start_with?(controller_path + '/')
    ''
  end
end
