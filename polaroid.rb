Shoes.setup do
  gem 'activesupport'
  gem 'rest-client'
  gem 'smile'
  gem 'rmagick'
end

require 'smile'
require 'rmagick'
require 'tempfile'

class Polaroid < Shoes::Widget
  attr_accessor :file_name, :photo, :clicked, :im
  def initialize(photo, args=nil)
    @photo = photo
    modifier = ( -10 .. 10 ).sort_by{ rand }.first
    index = (args[:index] || 1 ).to_f
    timer( index.to_f / 3 ) do
      convert_to_polaroid( photo, modifier )
    end
  end
  
  def convert_to_polaroid( photo, mod )
    download photo.small_url do |smug|
      @file_name = "#{photo.image_id}_#{photo.key}.png"
      @path = nil
      Tempfile.open( @file_name ) do |f|
        @path = f.path
        f << smug.response.body
      end
      
      @file_name = @path
      rimage = Magick::Image.read(@file_name).first

      rimage.border!(18, 18, "#f0f0ff")

      rimage.background_color = "none"

      amplitude  = rimage.columns * 0.01
      wavelength = rimage.rows  * 2

      rimage.rotate!(90)
      rimage = rimage.wave(amplitude, wavelength)
      rimage.rotate!(-90)

      shadow = rimage.flop
      shadow = shadow.colorize(1, 1, 1, "gray75")
      shadow.background_color = "white"
      shadow.border!(10, 10, "white")
      shadow = shadow.blur_image(0, 3)

      rimage = shadow.composite(rimage, -amplitude/2, 5, Magick::OverCompositeOp)

      rimage.rotate!(-5 + mod)
      #rimage.trim! # breakes in shoes it's odd

      rimage.write( @file_name )
    
      @im = image @file_name
      self.width = @im.full_width
    end
  end
  
  def loading?
    @im.nil?
  end
end

Shoes.app :title => "Widget Test" do
  @smug = Smile::Smug.new
  @smug.auth_anonymously
  @albums = @smug.albums( :NickName => "kleinpeter", :Heavy => 1 ).select{ |x| x.image_count.to_i > 1 }
  @album = @albums.first
  background white
  
  stack do
    @status = para "Loading...."
    @p = progress
  end
  @max = @album.photos.size
  @polaroids = Array.new( @max )
  
  animate( 2 ) do
    count = @polaroids.select{ |x| !x.loading? }.size
    @p.fraction = count.to_f / @max.to_f
    if @p.fraction == 1
      @status.replace "Done"
    else
      @status.replace "Loading....#{count} / #{@max}"
    end
  end

  @c = 0
  @polaroids = @album.photos.map { |p| polaroid p, :index => @c += 1  }
end