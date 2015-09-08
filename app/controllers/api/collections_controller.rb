module Api
  class  CollectionsController < Api::BaseController

    # POST /collections
    # POST /collections.json
    def create
      @collection = Collection.new(collections_params)
      @collection.exists = @collection.exists?
      if @collection.exists
        @collection.track_count = 0
        @collection.scanning = true
        @collection.save
        Thread.abort_on_exception = true
        Thread.new do
          print "new scan thread\n"
          track_count = @collection.scan
          print "track count #{track_count}\n"
          @collection.save
          ActiveRecord::Base.connection.close
        end
      end

      respond_to do |format|
        if @collection.save
          format.json { render json: @collection, status: :created}
        else
          format.json { render json: @_collection.errors, status: :unprocessable_entity }
        end
      end
    end

    def scan
      @collection = Collection.find(params[:id])

      Thread.abort_on_exception = true
      Thread.new do
        print "new scan thread\n"
        track_count = @collection.scan
        print "track count #{track_count}\n"
        @collection.save
        ActiveRecord::Base.connection.close
      end

      respond_to do |format|
        if @collection.save
          format.json { render json: @collection, status: :created}
        else
          format.json { render json: @_collection.errors, status: :unprocessable_entity }
        end
      end
    end

  private
    def collections_params
      params.require(:collection).permit(:path)
    end
  end
end
