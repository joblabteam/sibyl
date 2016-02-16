require_dependency "sibyl/application_controller"

module Sibyl
  class DashboardController < ApplicationController
    def index
      @panels = if params[:panels].is_a?(Hash)
                  params[:panels].values
                else
                  params[:panels]
                end
    end

    def show
    end
  end
end
