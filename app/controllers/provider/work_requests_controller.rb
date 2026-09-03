module Provider
  class WorkRequestsController < ApplicationController
    def show
      @work_request = WorkRequest
        .includes(:business, :required_skill, assignments: :staff_member)
        .find_by(id: params[:id], business_id: session[:business_id])

      return if @work_request

      redirect_to provider_detail_path, alert: "勤務依頼が見つかりませんでした。"
    end
  end
end
