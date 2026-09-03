require "test_helper"

class WorkRequestsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @business = Business.create!(
      name: "テスト会館",
      contact_name: "担当者",
      contact_phone: "00-0000-0000"
    )
    @other_business = Business.create!(
      name: "別会館",
      contact_name: "別担当者",
      contact_phone: "11-1111-1111"
    )
    @skill = Skill.create!(code: "RECEPTION_#{SecureRandom.hex(4)}", name: "受付")
    @work_request = WorkRequest.create!(
      business: @business,
      required_skill: @skill,
      title: "受付業務",
      starts_at: Time.zone.local(2026, 8, 20, 10),
      ends_at: Time.zone.local(2026, 8, 20, 12),
      required_staff_count: 1,
      notes: "集合場所は正面玄関"
    )
  end

  test "詳細画面に備考と編集リンクを表示する" do
    get work_request_path(@work_request)

    assert_response :success
    assert_select "h2", text: "備考"
    assert_select "p", text: "集合場所は正面玄関"
    assert_select "a[href=?]", edit_work_request_path(@work_request), text: "依頼を編集"
  end

  test "Providerは自社の勤務依頼を表示し編集リンクを表示しない" do
    post login_path, params: { role: "business", business_id: @business.id }

    get provider_work_request_path(@work_request)

    assert_response :success
    assert_select "h1", text: "受付業務"
    assert_select "p", text: "集合場所は正面玄関"
    assert_select "a[href=?]", edit_work_request_path(@work_request), count: 0
  end

  test "Providerが他社の勤務依頼へアクセスすると一覧へ戻る" do
    other_work_request = WorkRequest.create!(
      business: @other_business,
      required_skill: @skill,
      title: "別会館の受付業務",
      starts_at: Time.zone.local(2026, 8, 21, 10),
      ends_at: Time.zone.local(2026, 8, 21, 12),
      required_staff_count: 1
    )
    post login_path, params: { role: "business", business_id: @business.id }

    get provider_work_request_path(other_work_request)

    assert_redirected_to provider_detail_path
  end

  test "Providerが自社の勤務依頼を全項目編集できる" do
    post login_path, params: { role: "business", business_id: @business.id }

    get provider_work_request_path(@work_request)
    assert_select "a[href=?]", edit_provider_work_request_path(@work_request), text: "依頼を編集"

    get edit_provider_work_request_path(@work_request)
    assert_response :success
    assert_select "select[name=?]", "work_request[status]"
    assert_select "option[value=?]", "confirmed", count: 0
    assert_select "input[name=?]", "work_request[title]"
    assert_select "textarea[name=?]", "work_request[notes]"

    patch provider_work_request_path(@work_request), params: {
      work_request: {
        required_skill_id: @skill.id,
        title: "受付業務（更新）",
        starts_at: "2026-08-20T09:00",
        ends_at: "2026-08-20T12:30",
        required_staff_count: 2,
        status: "draft",
        notes: "集合場所は南側入口"
      }
    }

    assert_redirected_to provider_work_request_path(@work_request)
    @work_request.reload
    assert_equal "受付業務（更新）", @work_request.title
    assert_equal 2, @work_request.required_staff_count
    assert_equal "draft", @work_request.status
    assert_equal "集合場所は南側入口", @work_request.notes

    follow_redirect!
    assert_select ".alert-success", text: /勤務依頼を更新しました/
    assert_select "h1", text: "受付業務（更新）"
    assert_select "span.badge", text: /Draft/
  end

  test "Providerの勤務依頼作成画面を表示する" do
    post login_path, params: { role: "business", business_id: @business.id }

    get new_provider_work_request_path

    assert_response :success
    assert_select "h1", text: "勤務依頼の新規作成"
    assert_select "form[action=?]", provider_work_requests_path
  end

  test "Providerが作成した勤務依頼にログイン中の事業者IDを保存する" do
    post login_path, params: { role: "business", business_id: @business.id }

    assert_difference("WorkRequest.count", 1) do
      post provider_work_requests_path, params: {
        work_request: {
          required_skill_id: @skill.id,
          title: "新しい受付業務",
          starts_at: "2026-08-22T10:00",
          ends_at: "2026-08-22T12:00",
          required_staff_count: 2,
          status: "draft",
          notes: "作成時の備考"
        }
      }
    end

    assert_redirected_to provider_detail_path
    assert_equal @business.id, WorkRequest.order(:created_at).last.business_id
  end

  test "管理者向け勤務依頼作成画面は表示しない" do
    get "/work_requests/new"

    assert_response :not_found
  end

  test "備考だけを更新して詳細画面へ戻る" do
    assert_difference("ChangeEvent.count", 1) do
      patch work_request_path(@work_request), params: {
        work_request: {
          notes: "変更後は裏口へ集合",
          title: "この値は更新しない"
        }
      }
    end

    assert_redirected_to work_request_path(@work_request)
    assert_equal "変更後は裏口へ集合", @work_request.reload.notes
    assert_equal "受付業務", @work_request.title

    follow_redirect!
    assert_select ".alert-success", text: /勤務依頼の備考を更新しました/
    assert_select "p", text: "変更後は裏口へ集合"
  end

  test "備考編集画面を表示する" do
    get edit_work_request_path(@work_request)

    assert_response :success
    assert_select "h1", text: "勤務依頼を編集"
    assert_select "form[action=?]", work_request_path(@work_request)
    assert_select "textarea[name=?]", "work_request[notes]", text: "集合場所は正面玄関"
  end

  test "勤務依頼以外のRecordInvalidは編集画面へ渡さない" do
    error = ActiveRecord::RecordInvalid.new(ChangeEvent.new)
    original = WorkRequest.method(:update_details!)
    WorkRequest.define_singleton_method(:update_details!) { |**| raise error }

    patch work_request_path(@work_request), params: {
      work_request: { notes: "変更後の備考" }
    }

    assert_response :unprocessable_content
    assert_not_includes response.body, "勤務依頼を編集"
  ensure
    WorkRequest.define_singleton_method(:update_details!, original)
  end
end
