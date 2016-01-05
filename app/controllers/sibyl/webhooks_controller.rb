require_dependency "sibyl/application_controller"

module Sibyl
  class WebhooksController < ApplicationController
    respond_to :json

    def webhook
      p request.headers["Content-Type"]
      p request.headers["MIME Type"]
      p request.headers
      data = request.request_parameters[:webhook]
      p params
      p data
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
