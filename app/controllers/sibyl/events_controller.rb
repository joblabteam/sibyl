require_dependency "sibyl/application_controller"

module Sibyl
  class EventsController < ApplicationController
    before_action :set_event, only: [:show]

    def index
      @events = Event.all

      if params[:funnel]&.size&.> 1 # we are in a funnel!
        funnel_relation = Event.all
        funnel_results = { funnel: [] }
        first_value = nil

        params[:funnel]&.each_with_index do |funnel, i|
          funnel = funnel.last if funnel.is_a? Array
          last_index = params[:funnel].is_a?(Array) ? i - 1 : :"#{i - 1}"
          last_funnel = params[:funnel][last_index]
          last_funnel = last_funnel.last if last_funnel.is_a? Array

          # Select funnelled subset of Events - SELECT ... WHERE x IN (SELECT y FROM ...)
          funnel_relation = Event.all.where_funnel(funnel[:property], last_funnel[:property], funnel_relation) if i > 0
          funnel_relation = general_filters(funnel_relation, funnel)

          value = funnel_relation.operation(funnel[:operation], funnel[:property], funnel[:order])
          first_value = value unless first_value
          percent = (100.0 / first_value) * value

          funnel_results[:funnel] << {
            value: value,
            percent: percent,
            label: funnel[:title].blank? ? funnel[:kind] : funnel[:title]
          }
        end

        @events = funnel_results
      elsif params[:funnel]
        funnel = params[:funnel]
        funnel = funnel.is_a?(Hash) ? funnel[:"0"] : funnel[0]
        relation = Event.all

        relation = general_filters(relation, funnel)
        @events = relation.operation(funnel[:operation], funnel[:property], funnel[:order])
      else
        relation = Event.all
        @events = general_filters(relation, {})
      end

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

    def time_from_seconds(seconds)
      Time.at(Time.now - Time.at(seconds)).to_s
    end

    def safe_limit(funnel)
      limit = funnel[:limit].blank? ? false : funnel[:limit].to_i
      if funnel[:operation].blank?
        limit || 50
      else
        limit
      end
    end

    def general_filters(relation, funnel)
      relation = relation.in_kind(funnel[:kind])
      relation = relation.order_by(funnel[:order])

      funnel[:filters]&.each do |filter|
        filter = filter.last if filter.is_a? Array

        relation = relation.filter_property?(filter[:property])
        relation = relation.filter_property_value(
          filter[:filter], filter[:property], filter[:value]
        )
      end

      if funnel[:previous].blank?
        relation = relation.date_from funnel[:from] unless funnel[:from].blank?
        relation = relation.date_to funnel[:to] unless funnel[:to].blank?
      else
        relation = relation.date_previous funnel[:previous]
      end

      limit = safe_limit(funnel)
      relation = relation.limit(limit) unless limit.blank?

      relation = relation.interval(funnel[:interval]) unless funnel[:interval].blank?

      # @events = @events.group_by(funnel[:group], funnel[:order]) unless funnel[:group].blank?
      relation
    end
  end
end
