require_dependency "sibyl/application_controller"

module Sibyl
  class EventsController < ApplicationController
    before_action :set_event, only: [:show]

    # GET /events
    def index
      @events = Event.all
      @events = @events.where(kind: params[:kind]) unless params[:kind].blank?
      if params[:order].blank?
        @events = @events.order(occurred_at: :desc)
      else
        @events = @events.order(occurred_at: params[:order].to_sym)
      end
      @events = @events.target_property?(params[:target_property])
      @events = @events.target_property_value(params[:target_property], params[:target_value])
      @events = @events.operation(params[:operation], params[:target_property])

      @events = @events.date_from(params[:date_from]) unless params[:date_from].blank?
      @events = @events.date_to(params[:date_to]) unless params[:date_to].blank?
      @events = @events.limit(params[:limit].to_i) unless params[:limit].blank?
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
