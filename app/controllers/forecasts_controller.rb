class ForecastsController < ApplicationController
  def show
    @address = params[:address]

    if @address.blank?
      flash[:alert] = "Address cannot be empty"
      redirect_to forecasts_path
      return
    end

    @forecast = ForecastService.get_forecast(address: @address)

    if @forecast.blank?
      flash[:alert] = "Unable to get forecast for that address"
      redirect_to forecasts_path
    end
  end
end
