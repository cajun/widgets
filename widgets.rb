Shoes.setup do
  gem 'activesupport'
  gem 'rest-client'
  gem 'smile'
end

require 'smile'


class SPhoto < Shoes::Widget
  attr_accessor :file_name, :photo, :clicked
  def initialize(photo, args=nil)
    @photo = photo
    @clicked = false
    
    modifier = ( -50 .. 150 ).sort_by{ rand }.first
    @im = image photo.small_url
    @im.rotate modifier

    debug @im.methods.sort.join( ', ')
    click do |button,left,top|
      @last_left = left
      @last_top = top
      @clicked = true
    end
    
    release do |button,left,top|
      @clicked = false
    end
    
    motion do |left,top|
      if( @clicked )
        displace( @last_left - left, @last_top - top )
        @last_left = left
        @last_top = top
      end
    end
    
    self.top = modifier + 50
    self.left = modifier + 50
    self.width = @im.full_width
    self.height = @im.full_height
    
    #@ro = ( -5 .. 5 ).sort_by{ rand }.first
    #animate do |i|
    # @im.rotate( @ro ) 
    #end
    #
    #timer( 3 ) do
    #  @ro = 0
    #end
  end
end

Shoes.app :title => "Widget Test" do
  @smug = Smile::Smug.new
  @smug.auth_anonymously
  @albums = @smug.albums( :NickName => "kleinpeter", :Heavy => 1 ).select{ |x| x.image_count.to_i > 1 }
  @album = @albums.first
  background white
  @status = para "One Moment..."
  
  @p = progress
  
  @max = @album.photos.size - 1
  animate do |i|
    @p.fraction = ( ( @index || 0 ) / @max )
    @p.fraction == 1
  end
  
  @album.photos.each_with_index do |ph, index|
    @index = index
    s_photo ph
  end
  
end