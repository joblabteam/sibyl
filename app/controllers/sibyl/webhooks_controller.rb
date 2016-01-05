require_dependency "sibyl/application_controller"

module Sibyl
  class WebhooksController < ApplicationController
    def webhook
      Event.create_event "webhook_#{params[:sibyl_event]}",
        request.request_parameters[:webhook]

      unless request.headers["X-Hook-Secret"].blank?
        response.headers["X-Hook-Secret"] = request.headers["X-Hook-Secret"]
      end

      head :ok, content_type: "text/html"
    end
  end
end
