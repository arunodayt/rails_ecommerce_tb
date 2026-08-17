class CurrenciesController < ApplicationController
  include Authenticatable

  after_action :verify_policy_scoped, only: :index

  # GET /currencies
  def index
    authorize Currency, :index?
    currencies = policy_scope(Currency).order(:code)
    render json: currencies.map { |c| currency_json(c) }
  end

  # GET /currencies/:code
  def show
    currency = find_currency
    authorize currency
    render json: currency_json(currency)
  end

  # POST /currencies
  def create
    currency = Currency.new
    authorize currency
    currency.assign_attributes(permitted_attributes(currency))

    if currency.save
      render json: currency_json(currency), status: :created
    else
      render json: { errors: currency.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /currencies/:code
  def update
    currency = find_currency
    authorize currency

    if currency.update(permitted_attributes(currency))
      render json: currency_json(currency)
    else
      render json: { errors: currency.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /currencies/:code/refresh - re-fetch the USD rate from the provider
  def refresh
    currency = find_currency
    authorize currency
    currency.refresh_rate!
    render json: currency_json(currency)
  rescue ExchangeRateProvider::UnknownCurrency => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  private

  def find_currency
    Currency.find_by_code(params[:code]) || raise(ActiveRecord::RecordNotFound)
  end

  def currency_json(currency)
    {
      id:              currency.id,
      code:            currency.code,
      name:            currency.name,
      usd_rate:        currency.usd_rate.to_f,
      rate_updated_at: currency.rate_updated_at
    }
  end
end
