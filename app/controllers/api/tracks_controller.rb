module Api
  class  TracksController < Api::BaseController
    def data
        response.headers['X-Content-Duration'] = '311'
#        response.headers['Content-Type'] = 'audio/ogg'
        response.headers['Accept-Ranges'] = 'bytes'
	response.header['Cache-Control'] = 'public, must-revalidate, max-age=0'
	response.header['Pragma'] = 'no-cache'
	send_file '/home/sean/Music/mirah - 01 - cold cold water.ogg', :disposition => "inline", :type => "audio/ogg"
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
