class CsatSurveyResponsePolicy < ApplicationPolicy
  def index?
    has_permission?('report_manage')
  end

  def metrics?
    has_permission?('report_manage')
  end

  def download?
    has_permission?('report_manage')
  end
end

CsatSurveyResponsePolicy.prepend_mod_with('CsatSurveyResponsePolicy')
