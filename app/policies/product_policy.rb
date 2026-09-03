class ProductPolicy < ApplicationPolicy
  def index? = true
  def show?  = true

  def create?  = staff?
  def update?  = staff?
  def destroy? = staff?

  def permitted_attributes
    %i[sku name description price_cents active]
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.manager?
        scope.all
      else
        scope.active
      end
    end
  end

  private

  def staff?
    user.admin? || user.manager?
  end
end
