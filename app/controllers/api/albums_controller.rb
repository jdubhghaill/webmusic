module Api
  class  AlbumsController < Api::BaseController
    # GET /albums/1/image
    def image
      @album = Album.find(params[:album_id])
      response.header["Accept-Ranges"] = "bytes"
      if @album.image.nil?
        send_data '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg id="svg2985" xmlns="http://www.w3.org/2000/svg" height="120" width="120" version="1.1">
<g id="layer1" transform="translate(0,56)">
<rect id="rect3097" transform="translate(0,-56)" height="120" width="120" y="0" x="0" fill="#EEE"/>
<path id="path2997" d="m61.521,87.972a11.982,11.521,0,1,1,-23.963,0,11.982,11.521,0,1,1,23.963,0z" transform="translate(6.0436743,-69.117585)" fill="#CCC"/>
<rect id="rect2999" height="49.77" width="4.6083" y="-31.145" x="62.956" fill="#CCC"/>
<rect id="rect3001" transform="matrix(0.98171446,0.19035947,-0.10502306,0.99446979,0,0)" height="4.5872" width="18.861" y="-43.599" x="64.138" fill="#CCC"/>
</g>
</svg>', :type => "image/svg+xml", :filename => "album.svg"
      else
        send_data @album.image, :type => @album.image_type, :filename => "album.#{@album.image_type}"
      end
    end
  end
end
