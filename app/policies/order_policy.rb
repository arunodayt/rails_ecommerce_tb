class OrderPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = true

  def update?  = staff?
  def destroy? = staff?

  def permitted_attributes_for_create
    attrs = [ :customer_id, { order_items_attributes: %i[product_id quantity] } ]
    attrs << :status if staff?
    attrs
  end

  def permitted_attributes_for_update
    %i[status]
  end

  class Scope < Scope
    # Staff can see all orders.
    def resolve
      scope.all
    end
  end

  private

  def staff?
    user.admin? || user.manager?
  end
end
