class Views::Awards::Activity < Views::Base
  needs :project, :award_data, :current_auth

  def content
    column("small-12 grow") {
      h3 "Award History"
      div(class: 'content-box') {

        render partial: 'shared/award_progress_bar'

        if award_data[:contributions].present?
          p {
            div(id: "contributions-chart")
          }
          content_for :js do
            make_charts
          end
        end
      }
    }
  end


  def make_charts
    text(<<-JAVASCRIPT.html_safe)
      $(function() {
        window.stackedBarChart("#contributions-chart", #{award_data[:contributions_by_day].to_json});
      });
    JAVASCRIPT
  end

  def total_coins_issued
    award_data[:award_amounts][:total_coins_issued]
  end

  def percentage_issued
    total_coins_issued * 100 / project.maximum_coins.to_f
  end
end