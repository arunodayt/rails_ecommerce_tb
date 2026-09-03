class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager?
  end

  def show?
    user.admin? || user.manager? || self?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || self? || manages_member?
  end

  def destroy?
    (user.admin? && !self?) || manages_member?
  end

  def permitted_attributes
    attrs = %i[username password password_confirmation]
    attrs << :role if user.admin?
    attrs
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.manager?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end

  private

  def self?
    record.is_a?(User) && record.id == user.id
  end

  def manages_member?
    user.manager? && record.is_a?(User) && record.member?
  end
end
