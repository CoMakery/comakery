class Views::Layouts::Legacy < Views::Base
  use_instance_variables_for_assigns true
  needs :whitelabel_mission

  # rubocop:todo Metrics/PerceivedComplexity
  def content
    doctype!
    html(lang: 'en') do
      head do
        render partial: 'layouts/google_tag_manager.html'
        render partial: 'shared/unbounce.html'
        render partial: 'shared/meta_tags'

        stylesheet_link_tag 'application', media: 'all', 'data-turbo-track': 'reload'
        stylesheet_link_tag '//fonts.googleapis.com/css?family=Lato|Slabo+27px'
        stylesheet_link_tag '//fonts.googleapis.com/css?family=Montserrat:400,400i,500,500i,700&amp;subset=cyrillic,cyrillic-ext,latin-ext,vietnamese', defer: true
        stylesheet_link_tag '//cdnjs.cloudflare.com/ajax/libs/cookieconsent2/3.1.0/cookieconsent.min.css'
        javascript_include_tag '//cdnjs.cloudflare.com/ajax/libs/cookieconsent2/3.1.0/cookieconsent.min.js'
        javascript_include_tag 'turbo', type: 'module'
        yield :head
        javascript_include_tag :modernizr
        javascript_include_tag 'application', 'data-turbo-track': 'reload'

        javascript_include_tag Webpacker.manifest.lookup!('application.js')

        javascript_include_tag 'jquery.visible' if Rails.env.test?

        csrf_meta_tags
      end

      body(class: "#{controller_name}-#{action_name} #{current_account&.slack_auth ? '' : 'signed-out'}") do
        render partial: 'layouts/google_tag_no_script.html'

        text react_component(
          'layouts/Header',
          {
            is_admin: current_account&.comakery_admin?,
            is_logged_in: (current_account ? true : false),
            is_whitelabel: @whitelabel_mission.present?,
            whitelabel_logo: Attachment::GetPath.call(attachment: @whitelabel_mission&.whitelabel_logo).path,
            project_awards_visible: (@whitelabel_mission&.project_awards_visible? ? true : false),
            current_path: request.fullpath
          },
          prerender: true
        )

        render partial: 'layouts/project_search_form' unless @whitelabel_mission

        div(class: 'app-container row') do
          message unless current_page?(accounts_path)
          content_for?(:pre_body) ? yield(:pre_body) : ''
          div(class: 'main') do
            div(class: 'large-10 medium-11 small-12 small-centered columns no-h-pad', style: 'max-width: 1535px;') do
              content_for?(:body) ? yield(:body) : yield
            end
          end
        end

        text react_component('IntercomButton') unless @whitelabel_mission

        text react_component(
          'layouts/Footer',
          {
            is_logged_in: (current_account ? true : false),
            is_whitelabel: @whitelabel_mission.present?,
            whitelabel_logo: Attachment::GetPath.call(attachment: @whitelabel_mission&.whitelabel_logo).path,
            whitelabel_logo_dark: Attachment::GetPath.call(attachment: @whitelabel_mission&.whitelabel_logo_dark).path
          },
          prerender: true
        )

        if ENV['GOOGLE_ANALYTICS'].present?
          javascript_tag("
            (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
            (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
            })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

            ga('create', '#{ENV['GOOGLE_ANALYTICS']}', 'auto');
            ga('send', 'pageview');
          ")
        end

        if content_for?(:js)
          script do
            yield(:js)
          end
        end
      end
    end
  end

  def message
    div(class: 'large-12 medium-12 small-12 small-centered') do
      flash.each do |name, msg|
        div('aria-labelledby' => "flash-msg-#{name}", 'aria-role' => 'dialog', class: ['callout', 'flash-msg', name], 'data-alert' => '', 'data-closable' => '', style: 'padding-right: 30px;') do
          button('class' => 'close-button float-right', 'aria-label' => 'Close alert', 'data-close' => '') do
            span('aria-hidden' => true) { text 'x' }
          end
          span(id: "flash-msg-#{name}") do
            text ActiveSupport::SafeBuffer.new(html_escape(msg))
          end
        end
      end
      flash.clear
    end
  end
end
