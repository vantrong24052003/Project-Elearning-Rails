# frozen_string_literal: true

class QuestionsImportService
  attr_reader :file, :course_id, :user_id, :results

  def initialize(file, course_id, user_id)
    @file = file
    @course_id = course_id
    @user_id = user_id
    @results = {
      total: 0,
      success: 0,
      failed: 0,
      errors: []
    }
  end

  def import
    return { error: 'Không có file', total: 0, success: 0, failed: 0, errors: [] } if file.blank?
    return { error: 'Không có khóa học được chọn', total: 0, success: 0, failed: 0, errors: [] } if course_id.blank?

    begin
      xlsx = Roo::Spreadsheet.open(file.path)
      sheet = xlsx.sheet(0)

      headers = sheet.row(1)

      if headers.blank? || headers.compact.empty?
        return { error: 'File không đúng định dạng. Không tìm thấy header.', total: 0, success: 0, failed: 0,
                 errors: [] }
      end

      (2..sheet.last_row).each do |i|
        @results[:total] += 1
        begin
          row_data = sheet.row(i)

          next if row_data.compact.empty?

          row = Hash[[headers, row_data].transpose]

          options = {}
          (0..3).each do |j|
            option_key = "Đáp án #{('A'.ord + j).chr}"
            options[j.to_s] = row[option_key].presence || ''
          end

          if row['Nội dung câu hỏi'].blank?
            @results[:failed] += 1
            error_msg = "Dòng #{i}: Nội dung câu hỏi không được để trống"
            @results[:errors] << error_msg
            next
          end

          question = Question.new(
            content: row['Nội dung câu hỏi'],
            options: options,
            correct_option: row['Đáp án đúng (0-3)'].to_i,
            explanation: row['Giải thích'].presence || 'Không có giải thích',
            difficulty: row['Độ khó'].presence || 'medium',
            topic: row['Chủ đề'].presence || 'other',
            learning_goal: row['Mục tiêu học tập'].presence || 'other',
            course_id: course_id,
            user_id: user_id,
            status: row['Trạng thái'].presence || 'active',
            valid_until: parse_date(row['Thời hạn hiệu lực'])
          )

          if question.save
            @results[:success] += 1
          else
            @results[:failed] += 1
            error_msg = "Dòng #{i}: #{question.errors.full_messages.join(', ')}"
            @results[:errors] << error_msg
          end
        rescue StandardError => e
          @results[:failed] += 1
          error_msg = "Dòng #{i}: Lỗi xử lý - #{e.message}"
          @results[:errors] << error_msg
        end
      end

      @results
    rescue StandardError => e
      { error: "Lỗi xử lý file: #{e.message}", total: 0, success: 0, failed: 0, errors: [] }
    end
  end

  def preview_import
    return { error: 'Không có file', questions: [], validation_errors: [] } if file.blank?
    return { error: 'Không có khóa học được chọn', questions: [], validation_errors: [] } if course_id.blank?

    begin
      file_ext = File.extname(file.original_filename).downcase

      sheet = if file_ext == '.csv'
                Roo::CSV.new(file.path)
              else
                Roo::Spreadsheet.open(file.path)
              end

      sheet = sheet.sheet(0) unless file_ext == '.csv'

      headers = sheet.row(1)

      if headers.blank? || headers.compact.empty?
        return { error: 'File không đúng định dạng. Không tìm thấy header.', questions: [], validation_errors: [] }
      end

      preview_results = {
        questions: [],
        validation_errors: []
      }

      (2..sheet.last_row).each do |i|
        row_data = sheet.row(i)
        next if row_data.compact.empty?

        row = {}
        headers.each_with_index do |header, index|
          row[header] = row_data[index] if header.present?
        end

        options = {}
        (0..3).each do |j|
          option_key = "Đáp án #{('A'.ord + j).chr}"
          options[j.to_s] = row[option_key].presence || ''
        end

        if row['Nội dung câu hỏi'].blank?
          preview_results[:validation_errors] << {
            row: i,
            message: "Dòng #{i}: Nội dung câu hỏi không được để trống"
          }
          next
        end

        question_data = {
          content: row['Nội dung câu hỏi'],
          options: options,
          correct_option: row['Đáp án đúng (0-3)'].to_i,
          explanation: row['Giải thích'].presence || 'Không có giải thích',
          difficulty: row['Độ khó'].presence || 'medium',
          topic: row['Chủ đề'].presence || 'other',
          learning_goal: row['Mục tiêu học tập'].presence || 'other',
          course_id: course_id,
          user_id: user_id,
          status: row['Trạng thái'].presence || 'active',
          valid_until: parse_date_to_string(row['Thời hạn hiệu lực'])
        }

        preview_results[:questions] << question_data
      rescue StandardError => e
        preview_results[:validation_errors] << {
          row: i,
          message: "Dòng #{i}: Lỗi xử lý - #{e.message}"
        }
      end

      preview_results
    rescue StandardError => e
      { error: "Lỗi xử lý file: #{e.message}", questions: [], validation_errors: [] }
    end
  end

  def parse_date(date_value)
    return nil if date_value.blank?

    begin
      case date_value
      when String
        Date.parse(date_value)
      when Numeric
        base_date = Date.new(1899, 12, 30)
        base_date + date_value.to_i
      when Date
        date_value
      when DateTime, Time
        date_value.to_date
      end
    rescue StandardError
      nil
    end
  end

  def parse_date_to_string(date_value)
    return nil if date_value.blank?

    begin
      date = case date_value
             when String
               Date.parse(date_value)
             when Numeric
               base_date = Date.new(1899, 12, 30)
               base_date + date_value.to_i
             when Date
               date_value
             when DateTime, Time
               date_value.to_date
             end
      date&.to_s
    rescue StandardError
      nil
    end
  end

  def self.generate_template
    template = Axlsx::Package.new
    wb = template.workbook

    wb.add_worksheet(name: 'Câu hỏi') do |sheet|
      sheet.add_row [
        'Nội dung câu hỏi',
        'Đáp án A',
        'Đáp án B',
        'Đáp án C',
        'Đáp án D',
        'Đáp án đúng (0-3)',
        'Giải thích',
        'Độ khó',
        'Chủ đề',
        'Mục tiêu học tập',
        'Trạng thái',
        'Thời hạn hiệu lực'
      ]

      sheet.add_row [
        'Đâu là thủ đô của Việt Nam?',
        'Hà Nội',
        'Hồ Chí Minh',
        'Đà Nẵng',
        'Hải Phòng',
        '0',
        'Hà Nội là thủ đô của Việt Nam từ năm 1945',
        'easy',
        'geography',
        'remember',
        'active',
        '2025-12-31'
      ]

      sheet.add_row [
        'Ngôn ngữ lập trình nào được sử dụng trong Ruby on Rails?',
        'Ruby',
        'Python',
        'JavaScript',
        'PHP',
        '0',
        'Ruby on Rails là một framework được viết bằng ngôn ngữ Ruby',
        'medium',
        'programming',
        'understand',
        'active',
        ''
      ]
    end

    wb.add_worksheet(name: 'Hướng dẫn') do |sheet|
      sheet.add_row ['Hướng dẫn import câu hỏi']
      sheet.add_row ['']
      sheet.add_row ["1. Điền thông tin câu hỏi vào sheet 'Câu hỏi'"]
      sheet.add_row ['2. Không thay đổi cấu trúc cột']
      sheet.add_row ['3. Mỗi dòng là một câu hỏi']
      sheet.add_row ['4. Các trường bắt buộc: Nội dung câu hỏi, Đáp án A, Đáp án B, Đáp án C, Đáp án D, Đáp án đúng']
      sheet.add_row ['5. Đáp án đúng: Nhập 0 cho A, 1 cho B, 2 cho C, 3 cho D']
      sheet.add_row ['6. Độ khó: easy, medium, hard']
      sheet.add_row ['7. Chủ đề: math, physics, chemistry, biology, history, geography, literature, programming, other']
      sheet.add_row ['8. Mục tiêu học tập: remember, understand, apply, analyze, create, other']
      sheet.add_row ['9. Trạng thái: active, inactive, deprecated (mặc định là active)']
      sheet.add_row ['10. Thời hạn hiệu lực: Định dạng YYYY-MM-DD (ví dụ: 2025-12-31), để trống nếu không có thời hạn']
    end

    template
  end
end
