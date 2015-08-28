module Api
  class  TracksController < Api::BaseController
    def data
        response.headers['X-Content-Duration'] = '311'
        response.headers['Content-Type'] = 'audio/mpeg'
        response.headers['Accept-Ranges'] = 'bytes'
	send_file '/home/sean/Music/mirah - 01 - cold cold water.ogg'
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
