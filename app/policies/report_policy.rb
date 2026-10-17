class ReportPolicy < ApplicationPolicy
  def view?
    has_permission?('report_manage')
  end
end

ReportPolicy.prepend_mod_with('ReportPolicy')
