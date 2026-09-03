class CustomerPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = true

  def update?  = staff?
  def destroy? = staff?

  def permitted_attributes
    %i[name email]
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
