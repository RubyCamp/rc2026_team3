class WorkRequestsController < ApplicationController
  def index
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    @businesses = Business.for_selection
    @work_requests = WorkRequest
      .for_list
      .where(starts_at: @month..@month.end_of_month.end_of_day)
  end

  def new
    @work_request = WorkRequest.new
    @skills = Skill.all
  end

  def create
      @work_request = WorkRequest.create!(
        business_id: 1,

        required_skill_id: work_request_params[:required_skill_id],
        starts_at: work_request_params[:starts_at],
        ends_at: work_request_params[:ends_at],
        required_staff_count: work_request_params[:required_staff_count],
        title: work_request_params[:title],
        notes: work_request_params[:notes],
        status: work_request_params[:status]
      )

      redirect_to @work_request, notice: "勤務依頼を作成しました。"
    rescue ActiveRecord::RecordInvalid => error
      raise unless error.record.is_a?(WorkRequest)

      @work_request = error.record
      @skills = Skill.all
      render :new, status: :unprocessable_content
  end


  def show
    @work_request = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .find(params[:id])
  end

  def edit
    @work_request = WorkRequest.find(params[:id])
  end

  def update
    @work_request = WorkRequest.update_details!(
      id: params[:id],
      attributes: work_request_params
    )

    redirect_to @work_request, notice: "勤務依頼の備考を更新しました。"
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(WorkRequest)

    @work_request = error.record
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound
    redirect_to work_requests_path, alert: "更新する勤務依頼が見つかりませんでした。"
  end

  private

  def parse_month(value)
    return if value.blank?

    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end

  def work_request_params
    params.expect(work_request: [ :busines_id, :required_skill_id, :title, :starts_at, :ends_at, :required_staff_count, :status, :notes ])
  end
end
