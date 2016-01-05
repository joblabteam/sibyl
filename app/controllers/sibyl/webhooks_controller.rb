require_dependency "sibyl/application_controller"

module Sibyl
  class WebhooksController < ApplicationController
    def webhook
      if request.content_type.blank?
        data = JSON.parse(params.except(*request.path_parameters.keys).keys[0])
      else
        data = request.request_parameters[:webhook]
      end

      unless data.blank?
        Event.create_event "webhook_#{params[:sibyl_event]}", data
      end

      unless request.headers["X-Hook-Secret"].blank?
        response.headers["X-Hook-Secret"] = request.headers["X-Hook-Secret"]
      end

      head :ok, content_type: "text/html"
    end
  end
end
