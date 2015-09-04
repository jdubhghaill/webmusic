module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :authenticate_user!
    before_action :api_set_resource, only: [:destroy, :show, :update]
    respond_to :json

    # POST /api/{plural_resource_name}
    def create
      api_set_resource(resource_class.new(resource_params))

      if api_get_resource.save
        render :show, status: :created
      else
        render json: api_get_resource.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/{plural_resource_name}/1
    def destroy
      api_get_resource.destroy
      head :no_content
    end

    # GET /api/{plural_resource_name}
    def index
      plural_resource_name = "@#{api_resource_name.pluralize}"
      resources = api_resource_class.where(query_params)
                                .page(page_params[:page])
                                .per(page_params[:page_size])

      instance_variable_set(plural_resource_name, resources)
      respond_with instance_variable_get(plural_resource_name)
    end

    # GET /api/{plural_resource_name}/1
    def show
      respond_with api_get_resource
    end

    # PATCH/PUT /api/{plural_resource_name}/1
    def update
      if api_get_resource.update(resource_params)
        render :show
      else
        render json: api_get_resource.errors, status: :unprocessable_entity
      end
    end

    private

      # Returns the resource from the created instance variable
      # @return [Object]
      def api_get_resource
        instance_variable_get("@#{api_resource_name}")
      end

      # Returns the allowed parameters for searching
      # Override this method in each API controller
      # to permit additional parameters to search on
      # @return [Hash]
      def query_params
        {}
      end

      # Returns the allowed parameters for pagination
      # @return [Hash]
      def page_params
        params.permit(:page, :page_size)
      end
      # The resource class based on the controller
      # @return [Class]
      def api_resource_class
        @resource_class ||= api_resource_name.classify.constantize
      end

      # The singular name for the resource class based on the controller
      # @return [String]
      def api_resource_name
        @resource_name ||= self.controller_name.singularize
      end

      # Only allow a trusted parameter "white list" through.
      # If a single resource is loaded for #create or #update,
      # then the controller for the resource must implement
      # the method "#{resource_name}_params" to limit permitted
      # parameters for the individual model.
      def resource_params
        @resource_params ||= self.send("#{api_resource_name}_params")
      end

      # Use callbacks to share common setup or constraints between actions.
      def api_set_resource(resource = nil)
        resource ||= api_resource_class.find(params[:id])
        instance_variable_set("@#{api_resource_name}", resource)
      end
  end
end
