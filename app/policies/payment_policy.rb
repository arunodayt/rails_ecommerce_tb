class PaymentPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = true

  def permitted_attributes
    %i[amount_cents currency_code payment_method reference notes paid_at]
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
