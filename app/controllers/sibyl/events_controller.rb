require_dependency "sibyl/application_controller"

module Sibyl
  class EventsController < ApplicationController
    before_action :set_event, only: [:show]

    # GET /events
    def index
      @events = Event.all.order(occurred_at: :desc).limit(20)
    end

    # GET /events/1
    def show
    end

    # POST /events
    def create
      @event = Event.new

      respond_to do |format|
        format.json do
          if @event.from_json(event_params).save
            render json: @event, status: :created#, location: @user
          else
            render json: @event.errors, status: :unprocessable_entity
          end
        end
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_event
        @event = Event.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def event_params
        params.require(:event).permit(:type, :occurred_at, :data)
      end
  end
end
