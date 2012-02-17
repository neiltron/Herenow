HotCocoa::Mappings.map movie_view: QTMovieView do

  defaults layout: {}, frame: CGRectZero

  def init_with_options movie_view, options
    movie_view.initWithFrame(options.delete :frame)
  end

  custom_methods do
    def controller_visible= value
      setControllerVisible value
    end

    ##
    # @todo Change this method to use varargs in the future when we
    #       start deprecating things
    def controller_buttons= buttons
      setBackButtonVisible      buttons.include? :back
      setCustomButtonVisible    buttons.include? :custom
      setHotSpotButtonVisible   buttons.include? :hot_spot
      setStepButtonsVisible     buttons.include? :step
      setTranslateButtonVisible buttons.include? :translate
      setVolumeButtonVisible    buttons.include? :volume
      setZoomButtonsVisible     buttons.include? :zoom
    end
  end

end
