# frozen_string_literal: true

class Manage::QuestionsTemplatesController < Manage::BaseController
  def show
    respond_to do |format|
      format.xlsx do
        template = QuestionsImportService.generate_template
        send_data template.to_stream.read,
                  filename: "template_import_cau_hoi.xlsx",
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      end
    end
  end
end
