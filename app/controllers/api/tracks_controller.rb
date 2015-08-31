module Api
  class  TracksController < Api::BaseController
    def data
	response.headers['Content-Type'] = 'audio/ogg'
	response.headers['Cache-Control'] = 'public, must-revalidate, max-age=0'
	response.headers['X-Accel-Buffering'] = 'no'
	response.headers['X-Accel-Redirect'] = '/protected/mirah - 01 - cold cold water.ogg'

	render :nothing => true
    end

    private

      def track_params
        params.require(:track).permit(:title)
      end

      def query_params
        params.permit(:id, :title)
      end
  end
end
