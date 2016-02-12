require_dependency "sibyl/application_controller"

module Sibyl
  class EventsController < ApplicationController
    before_action :set_event, only: [:show]

    def index
      @events = Event.all
      @events = @events.where(kind: params[:kind]) unless params[:kind].blank?
      @events = if params[:order].blank?
                  @events.order(occurred_at: :desc)
                else
                  @events.order(occurred_at: params[:order].to_sym)
                end
      @events = @events.target_property?(params[:property])
      @events = @events.target_property_value(params[:property], params[:value])

      from, to = set_from_to
      @events = @events.date_from(from) unless from.blank?
      @events = @events.date_to(to) unless to.blank?
      limit = set_limit
      @events = @events.limit(limit) unless limit.blank?

      @events = @events.operation(params[:operation], params[:property])

      respond_to do |format|
        format.json do
          render json: @events
        end
        format.html {}
      end
    end

    def create
      @event = Event.new

      respond_to do |format|
        format.json do
          if @event.from_json(event_params).save
            render json: @event, status: :created # , location: @user
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

    def set_from_to
      if params[:previous].blank?
        [params[:from], params[:to]]
      else
        seconds = 60 * params[:previous].to_i
        [time_from_seconds(seconds), Time.now.to_s]
      end
    end

    def time_from_seconds(seconds)
      Time.at(Time.now - Time.at(seconds)).to_s
    end

    def set_limit
      limit = params[:limit].blank? ? false : params[:limit].to_i
      if params[:operation].blank?
        limit || 50
      else
        limit
      end
    end
  end
end
