module Provider
  class WorkRequestsController < ApplicationController
    def new
      @work_request = WorkRequest.new
      @skills = Skill.for_selection
    end

    def create
      @work_request = WorkRequest.create!(
        work_request_params.merge(business_id: session[:business_id])
      )

      redirect_to provider_detail_path, notice: "勤務依頼を作成しました。"
    rescue ActiveRecord::RecordInvalid => error
      raise unless error.record.is_a?(WorkRequest)

      @work_request = error.record
      @skills = Skill.for_selection
      render :new, status: :unprocessable_content
    end

    def show
      @work_request = WorkRequest
        .includes(:business, :required_skill, assignments: :staff_member)
        .find_by(id: params[:id], business_id: session[:business_id])

      return if @work_request

      redirect_to provider_detail_path, alert: "勤務依頼が見つかりませんでした。"
    end

    private

    def work_request_params
      params.expect(work_request: [ :required_skill_id, :title, :starts_at, :ends_at, :required_staff_count, :status, :notes ])
    end
  end
end
