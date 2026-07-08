class FrontendController < ApplicationController
  skip_before_action :default_json_format

  def show
    index_path = Rails.public_path.join("index.html")

    if index_path.exist?
      send_file index_path, type: "text/html", disposition: "inline"
    else
      head :not_found
    end
  end
end
