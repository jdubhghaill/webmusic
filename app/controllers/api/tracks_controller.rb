module Api
  class  TracksController < Api::BaseController
    def data
	file_begin = 0
	file_size = 6836450 
	file_end = file_size - 1

	if !request.headers["Range"]
	  status_code = "200 OK"
	else
	  status_code = "206 Partial Content"
	  match = request.headers['range'].match(/bytes=(\d+)-(\d*)/)
	  if match
	    file_begin = match[1]
	    file_end = match[1] if match[2] && !match[2].empty?
	  end
	  response.header["Content-Range"] = "bytes " + file_begin.to_s + "-" + file_end.to_s + "/" + file_size.to_s
	end
	response.header["Content-Length"] = (file_end.to_i - file_begin.to_i + 1).to_s


        response.headers['Content-Duration'] = '311'
        response.headers['X-Content-Duration'] = '311'
        response.headers['Accept-Ranges'] = 'bytes'
	response.header['Cache-Control'] = 'public, must-revalidate, max-age=0'
	response.header['Pragma'] = 'no-cache'
	response.header['X-Accel-Buffering'] = 'no'

	send_file '/home/sean/Music/mirah - 01 - cold cold water.ogg', :disposition => "inline", :type => "audio/ogg", :status => status_code
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
