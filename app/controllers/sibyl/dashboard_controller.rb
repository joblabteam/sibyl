require_dependency "sibyl/application_controller"

module Sibyl
  class DashboardController < ApplicationController
    def index
      @panels = params[:panels]&.values
    end

    def show
    end
  end
end
