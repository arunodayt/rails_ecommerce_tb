class InventoryPolicy < ApplicationPolicy
  def show?   = true
  def update? = staff?

  def permitted_attributes
    %i[quantity]
  end

  private

  def staff?
    user.admin? || user.manager?
  end
end
