class CurrencyPolicy < ApplicationPolicy
  def index? = true
  def show?  = true

  def create?  = staff?
  def update?  = staff?
  def refresh? = staff?

  def permitted_attributes
    %i[code name usd_rate]
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private

  def staff?
    user.admin? || user.manager?
  end
end
