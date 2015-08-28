module Api
  class  TracksController < Api::BaseController
    def data
	file_begin = 0
	file_size = 6836450 
	file_end = file_size - 1

	#response.header["Content-Length"] = (file_end.to_i - file_begin.to_i + 1).to_s


#        response.headers['Content-Duration'] = '311'
#        response.headers['X-Content-Duration'] = '311'
#        response.headers['Accept-Ranges'] = 'bytes'
	response.headers['Cache-Control'] = 'public, must-revalidate, max-age=0'
#	response.headers['Pragma'] = 'no-cache'
	response.headers['X-Accel-Buffering'] = 'no'
	response.headers['Content-Type'] = 'audio/ogg'
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
