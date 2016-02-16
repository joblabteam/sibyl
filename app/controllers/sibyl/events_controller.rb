require_dependency "sibyl/application_controller"

module Sibyl
  class EventsController < ApplicationController
    before_action :set_event, only: [:show]

    def index
      @events = Event.all
      @events = @events.in_kind(params[:kind])
      @events = @events.order_by(params[:order])
      params[:filters]&.each do |filter|
        filter = filter.last if filter.is_a? Array
        @events = @events.filter_property?(filter[:property])
        @events = @events.filter_property_value(
          filter[:filter], filter[:property], filter[:value]
        )
      end

      if params[:previous].blank?
        @events = @events.date_from params[:from] unless params[:from].blank?
        @events = @events.date_to params[:to] unless params[:to].blank?
      else
        @events = @events.date_previous params[:previous]
      end

      limit = set_limit
      @events = @events.limit(limit) unless limit.blank?

      @events = @events.interval(params[:interval]) unless params[:interval].blank?

      # @events = @events.group_by(params[:group], params[:order]) unless params[:group].blank?

      # must come last as doesn't return a relation
      @events = @events.operation(params[:operation], params[:property], params[:order])



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
