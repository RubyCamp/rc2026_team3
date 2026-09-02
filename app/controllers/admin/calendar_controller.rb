module Admin
  class CalendarController < ApplicationController
    def index
      @work_requests = WorkRequest.for_list
    end
  end
end
