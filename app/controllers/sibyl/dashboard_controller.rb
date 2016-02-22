require_dependency "sibyl/application_controller"
require "zlib"
require "json"

module Sibyl
  class DashboardController < ApplicationController
    def index
      @params = JSON.parse(Zlib.inflate(Base64.decode64(params[:zlib]))) rescue {}
      @panels = @params["panels"] || []
      # @panels = if params[:panels].is_a?(Hash)
                  # params[:panels].values
                # else
                  # params[:panels]
                # end
    end

    def show
    end
  end
end
