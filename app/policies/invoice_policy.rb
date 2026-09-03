class InvoicePolicy < ApplicationPolicy
  def index? = true
  def show?  = true

  def create? = staff?
  def update? = staff?

  def permitted_attributes_for_create
    %i[tax_rate]
  end

  def permitted_attributes_for_update
    %i[status]
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
