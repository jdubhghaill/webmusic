module Api
  class  TracksController < Api::BaseController
    def data
      @track = Track.find(params[:id])
	    response.headers['Content-Type'] = "audio/#{@track.mimetype}"
	    response.headers['Cache-Control'] = 'public, must-revalidate, max-age=0'
	    response.headers['X-Accel-Buffering'] = 'no'
	    response.headers['X-Accel-Redirect'] = "/protected#{encode(@track.location)}"

	    render :nothing => true
    end

    private

      def encode (uri)
        uri.gsub("%","%25")
      end

      def track_params
        params.require(:track).permit(:title)
      end

      def query_params
        params.permit(:id, :title)
      end
  end
end
