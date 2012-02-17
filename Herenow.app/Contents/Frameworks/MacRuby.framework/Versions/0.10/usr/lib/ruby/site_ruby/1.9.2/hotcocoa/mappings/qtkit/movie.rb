HotCocoa::Mappings.map movie: QTMovie do

  def alloc_with_options options
    if options.has_key? :file
      QTMovie.movieWithFile options.delete(:file), error:options.delete(:error)

    elsif options.has_key? :url
      QTMovie.movieWithURL NSURL.URLWithString(options.delete :url), error:options.delete(:error)

    else
      raise 'Can only allocate a movie from a file or a url'
    end
  end

end
