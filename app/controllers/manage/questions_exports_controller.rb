# frozen_string_literal: true

class Manage::QuestionsExportsController < Manage::BaseController
  def show
    query = Question.all.includes(:course, :user)

    query = query.where(course_id: params[:course_id]) if params[:course_id].present?
    query = query.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    query = query.where(topic: params[:topic]) if params[:topic].present?
    query = query.where(learning_goal: params[:learning_goal]) if params[:learning_goal].present?
    query = query.where(status: params[:status]) if params[:status].present?
    query = query.where('content ILIKE ?', "%#{params[:search]}%") if params[:search].present?

    query = query.order(created_at: :desc)

    questions = query.all

    respond_to do |format|
      format.xlsx do
        package = generate_excel(questions)
        send_data package.to_stream.read,
                  filename: "danh_sach_cau_hoi_#{Time.current.strftime('%d%m%Y_%H%M')}.xlsx",
                  type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      end
    end
  end

  private

  def generate_excel(questions)
    package = Axlsx::Package.new
    wb = package.workbook

    wb.add_worksheet(name: 'Danh sách câu hỏi') do |sheet|
      sheet.add_row [
        'ID',
        'Nội dung câu hỏi',
        'Đáp án A',
        'Đáp án B',
        'Đáp án C',
        'Đáp án D',
        'Đáp án đúng',
        'Đáp án đúng (A-D)',
        'Giải thích',
        'Khóa học',
        'Độ khó',
        'Chủ đề',
        'Mục tiêu học tập',
        'Trạng thái',
        'Thời hạn hiệu lực',
        'Ngày tạo'
      ]

      questions.each do |question|
        options = question.options || {}
        correct_option_letter = begin
          ('A'.ord + question.correct_option.to_i).chr
        rescue StandardError
          nil
        end

        sheet.add_row [
          question.id,
          question.content,
          options['0'],
          options['1'],
          options['2'],
          options['3'],
          question.correct_option,
          correct_option_letter,
          question.explanation,
          question.course&.title,
          question.difficulty,
          question.topic,
          question.learning_goal,
          question.status,
          question.valid_until&.strftime('%d/%m/%Y'),
          question.created_at&.strftime('%d/%m/%Y %H:%M')
        ]
      end
    end

    package
  end
end
