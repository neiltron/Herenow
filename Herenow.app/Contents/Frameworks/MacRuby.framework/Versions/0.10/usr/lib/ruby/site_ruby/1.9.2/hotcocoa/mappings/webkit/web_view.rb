HotCocoa::Mappings.map web_view: WebView do

  defaults layout: {}, frame: CGRectZero

  def init_with_options web_view, options
    web_view.initWithFrame options.delete :frame
  end

  custom_methods do
    def url= url
      url = NSURL.URLWithString(url) if url.kind_of? String
      mainFrame.loadRequest NSURLRequest.requestWithURL url
    end

    def auto_size
      setAutoresizingMask(NSViewHeightSizable|NSViewWidthSizable)
    end
  end

end
