module Api
  class  TracksController < Api::BaseController
    def data
	send_file '/protected/mirah - 01 - cold cold water.ogg'
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
