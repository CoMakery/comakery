module Views
  module Projects
    class SettingsForm < Views::Base
      needs :project, :providers, :provider_data, :current_section

      def content
        form_for project do |f|
          hidden_field_tag :current_section, current_section
          div(class: "content-box switch-target#{visible_class('#general')}", 'data-id': 'general-info', id: 'general') do
            div(class: 'legal-box-header') { h3 'General Info' }
            row do
              column('large-6 small-12') do
                with_errors(project, :title) do
                  label do
                    required_label_text 'Title'
                    f.text_field :title
                  end
                end

                with_errors(project, :description) do
                  label do
                    required_label_text 'Description'
                    f.text_area :description
                  end
                  link_to('Styling with Markdown is Supported', 'https://guides.github.com/features/mastering-markdown/', class: 'help-text float-right')
                end

                with_errors(project, :legal_project_owner) do
                  label(class: 'legal-project-owner') do
                    required_label_text "Project Owner's Legal Name "
                    question_tooltip 'The name of the company, association, legal entity, or individual that owns the project and administers awards.'
                    f.text_field :legal_project_owner, disabled: project.license_finalized?
                  end
                end

                with_errors(project, :denomination) do
                  label do
                    text 'Display Currency'
                    question_tooltip 'This is the currency that will be used for display by default. Revenues for revenue sharing will be counted in the currency it was received in.'
                    f.select(:denomination,
                      [['US Dollars ($)', 'USD'], ['Bitcoin (฿)', 'BTC'], ['Ether (Ξ)', 'ETH']], { selected: project.denomination, include_blank: false },
                      disabled: project.license_finalized? || project.revenues.any?)
                  end
                end
              end

              column('large-6 small-12') do
                with_errors(project, :tracker) do
                  label do
                    i(class: 'fa fa-tasks')
                    text ' Project Tracker'
                    f.text_field :tracker, placeholder: 'https://trello.com/my-project'
                  end
                end
                with_errors(project, :video_url) do
                  label do
                    i(class: 'fa fa-youtube')
                    text ' Video '
                    question_tooltip 'A video url representing your project. Must be a Youtube url.'
                    f.text_field :video_url, placeholder: 'https://www.youtube.com/watch?v=Dn3ZMhmmzK0'
                  end
                end
                with_errors(project, :image) do
                  label do
                    text 'Project Image '
                    question_tooltip 'An image that is at least 450 x 400 pixels is recommended.'
                    text f.attachment_field(:image)
                  end
                  text attachment_image_tag(project, :image, class: 'project-image')
                end
              end
            end
            render_cancel_and_save_buttons(f)
          end

          render partial: '/projects/form/channel', locals: { f: f, providers: providers, current_section: current_section }

          div(class: "content-box switch-target#{visible_class('#contribution')}", id: 'contribution', 'data-id': 'contribution-terms') do
            full_row do
              div(class: 'hide legal-box-header') do
                h3 'Contribution Terms'
                i(class: 'fa fa-lock') if project.license_finalized?
              end
            end
            row(class: 'hide') do
              column('large-6 small-12') do
                with_errors(project, :exclusive_contributions) do
                  label do
                    f.check_box :exclusive_contributions, disabled: project.license_finalized?
                    text 'Contributions are exclusive to this project '
                    question_tooltip 'When contributions are exclusive contributors may not gives others license for their contributions.'
                  end
                end

                with_errors(project, :require_confidentiality) do
                  label do
                    f.check_box :require_confidentiality, disabled: project.license_finalized?
                    text 'Require project and business confidentiality '
                    question_tooltip 'If project requires project confidentiality contributors agree to keep information about this agreement, other contributions to the Project, royalties awarded for other contributions, revenue received, royalties paid to the contributors and others, and all other unpublished information about the business, plans, and customers of the Project secret. Contributors also agree to keep copies of their contributions, copies of other materials contributed to the Project, and information about their content and purpose secret.'
                  end
                end
              end
            end
            br
            full_row do
              div(class: 'legal-box-header') { h4 'Blockchain Settings' }
            end
            row do
              column('large-6 small-12') do
                selected = f.object.ethereum_network
                selected = 'main' if project.completed_awards.blank? && f.object.ethereum_network.blank?
                options = capture do
                  options_for_select(ethereum_network_options, selected: selected)
                end
                with_errors(project, :ethereum_network) do
                  label do
                    text 'Network'
                    f.select :ethereum_network, options, { include_blank: true }, disabled: project.completed_awards.any?
                  end
                end

                with_errors(project, :ethereum_contract_address) do
                  label do
                    text 'Contract Address'
                    f.text_field :ethereum_contract_address, placeholder: '0x583cbBb8a8443B38aBcC0c956beCe47340ea1367', disabled: project.completed_awards.any?
                  end
                end

                with_errors(project, :maximum_tokens) do
                  label do
                    required_label_text 'Token Budget'
                    f.text_field :maximum_tokens, type: 'number', disabled: project.license_finalized? || project.ethereum_enabled?
                  end
                end

                with_errors(project, :maximum_royalties_per_month) do
                  label do
                    required_label_text 'Maximum Awarded Per Month'
                    f.text_field :maximum_royalties_per_month,
                      type: :number, placeholder: '25000',
                      disabled: project.license_finalized?
                  end
                end
                div(class: "revenue-sharing-terms #{'hide' if project.project_token?}") do
                  with_errors(project, :royalty_percentage) do
                    label do
                      required_label_text 'Revenue Shared With Contributors'
                      question_tooltip "The Project Owner agrees to count money customers pay either to license, or to use a hosted instance of, the Project as 'Revenue'. Money customers pay for consulting, training, custom development, support, and other services related to the Project does not count as Revenue."
                      # percentage_div { f.text_field :royalty_percentage, placeholder: "5%", class: 'input-group-field' }
                      percentage_div f, :royalty_percentage, placeholder: '10',
                                                             disabled: project.license_finalized?
                    end
                  end
                end
                if project.revenue_share?
                  div do
                    with_errors(project, :revenue_sharing_end_date) do
                      label do
                        text 'Revenue Sharing End Date'
                        f.text_field :revenue_sharing_end_date, class: 'datepicker-no-limit', placeholder: 'mm/dd/yyyy', value: f.object.revenue_sharing_end_date&.strftime('%m/%d/%Y'), disabled: project.license_finalized?
                        div(class: 'help-text') { text '"mm/dd/yyy" means revenue sharing does not end.' }
                      end
                    end
                  end
                end

                with_errors(project, :token_symbol) do
                  label do
                    text 'Token Symbol'
                    f.text_field :token_symbol
                  end
                end

                with_errors(project, :decimal_places) do
                  label do
                    text 'Decimal Places'
                    f.text_field :decimal_places, disabled: project.completed_awards.any?
                  end
                end

                # # Uncomment this after legal review  of licenses, disclaimers, etc.
                # with_errors(project, :license_finalized) {
                #   label {
                #     f.check_box :license_finalized, disabled: project.license_finalized?
                #     text 'The Contribution License Revenue Sharing Terms Are Finalized'
                #     div(class: 'help-text') { text "Leave this unchecked if you want to use #{I18n.t('project_name')} for tracking contributions with no legal agreement for sharing revenue." }
                #   }
                # }
              end

              column('large-6 small-12') do
                br
                div(class: "revenue-sharing-terms #{'hide' if project.project_token?}") do
                  h5 'Example'
                  table(class: 'royalty-calc') do
                    thead do
                      tr do
                        th { text 'Revenue' }
                        th { text 'Shared' }
                      end
                    end
                    tbody do
                      tr do
                        td(class: 'revenue') {}
                        td(class: 'revenue-shared') {}
                      end
                    end
                  end
                end
              end
            end
            render_cancel_and_save_buttons(f)
          end
          div(class: "content-box switch-target#{visible_class('#award')}", id: 'award', 'data-id': 'awards-offered') do
            div(class: 'award-types') do
              div(class: 'legal-box-header') { h3 'Awards Offered' }
              row do
                column('small-3') { text 'Contribution Type' }
                column('small-1') { text 'Amount ' }
                column('small-1') do
                  text 'Community Awardable '
                  question_tooltip 'Check this box if you want people on your team to be able to award others. Otherwise only the project owner can send awards.'
                end
                column('small-4 lb-description') do
                  text 'Description'
                  br
                  link_to('Styling with Markdown is Supported', 'https://guides.github.com/features/mastering-markdown/', class: 'help-text')
                end
                column('small-1') { text 'Disable' }
                column('small-2', class: 'text-center') do
                  text 'Remove '
                  question_tooltip 'Award type cannot be changed after awards have been issued.'
                end
              end

              project.award_types.build(amount: 0) if project.award_types.select { |award_type| award_type.amount == 0 }.blank?
              f.fields_for(:award_types) do |ff|
                row(class: "award-type-row#{ff.object.amount == 0 ? ' hide award-type-template' : ''}") do
                  ff.hidden_field :id
                  ff.hidden_field :_destroy, 'data-destroy': ''
                  column('small-3') { ff.text_field :name }
                  column('small-1 award-amount') do
                    readonly = !ff.object&.modifiable?
                    if readonly
                      tooltip("Award types' amounts can't be modified if there are existing awards", if: readonly) do
                        ff.text_field :amount, type: :number, class: 'text-right', readonly: readonly
                      end
                    else
                      ff.text_field :amount, type: :number, class: 'text-right', readonly: readonly
                    end
                  end
                  column('small-1', class: 'text-center') { ff.check_box :community_awardable }
                  column('small-4', class: 'text-center lb-description') { ff.text_area :description, class: 'award-type-description' }
                  column('small-1', class: 'text-center') { ff.check_box :disabled }
                  column('small-2', class: 'text-center') do
                    if ff.object&.modifiable?
                      a('×', href: '#', 'data-mark-and-hide': '.award-type-row', class: 'close')
                    else
                      text "(#{pluralize(ff.object.awards.count, 'award')} sent)"
                    end
                  end
                end
              end
            end
            row(class: 'add-award-type') do
              column do
                p { a('+ add award type', href: '#', 'data-duplicate': '.award-type-template') }
              end
            end
            render_cancel_and_save_buttons(f)
          end
          visibility_block(f, visibility_options)

          full_row do
            f.submit 'Save', class: buttonish(:expand, :last_submit)
          end
        end
      end

      def visibility_block(f, visibility_options)
        div(class: "content-box switch-target#{visible_class('#visibility')}", id: 'visibility', 'data-id': 'visibility') do
          div(class: 'award-types') do
            div(class: 'legal-box-header') { h3 'Visibility' }
            row do
              column('small-5') do
                options = capture do
                  options_for_select(visibility_options, selected: f.object.visibility)
                end
                label do
                  text 'Project Visible To'
                  f.select :visibility, options
                end
              end
            end
            row do
              label(style: 'margin-left: 15px;') do
                text 'Project URL'
              end
              column('small-5') do
                text_field_tag :unlisted_url, unlisted_project_url(f.object.long_id), name: nil, class: 'copy-source'
                hidden_field_tag :long_id, f.object.long_id
              end
              column('small-1', style: 'padding-left: 0; margin-left: -16px; margin-top: 8px') do
                a(class: 'copiable', style: 'padding: 9px; border: 1px solid #ccc;') do
                  image_tag 'Octicons-clippy.png', size: '20x20'
                end
              end
              column('small-1') {}
            end
          end
        end
        content_for :js do
          contract_address_on_change
        end
      end

      def percentage_div(form, field_name, **opts)
        opts[:class] = "#{opts[:class]} input-group-field"

        div(class: 'input-group') do
          span(class: 'input-group-label percentage') { text '%' }
          form.text_field field_name, **opts
        end
      end

      def visibility_options
        [['Logged in team members', 'member'], ['Publicly listed in CoMakery searches', 'public_listed'], ['Logged in team member via unlisted url', 'member_unlisted'], ['Unlisted url (no login required)', 'public_unlisted'], ['Archived (visible to me only)', 'archived']]
      end

      def ethereum_network_options
        Project.ethereum_networks.invert
      end

      def render_cancel_and_save_buttons(form)
        full_row_right do
          link_to 'Cancel', project, class: 'button cancel'
          form.submit 'Save', class: buttonish(:expand)
        end
      end

      def contract_address_on_change
        text(<<-JAVASCRIPT.html_safe)
          $(function() {
            $('body').on('change', "[name='project[ethereum_contract_address]']", function() {
              var network = $("[name='project[ethereum_network]']").val();
              var symbol = $("[name='project[token_symbol]']").val();
              var decimals = $("[name='project[decimal_places]']").val()
              if(network && network != '' && $(this).val() != '' && symbol == '' && decimals =='') {
                var rs = getSymbolsAndDecimals(network, $(this).val())
                $("[name='project[token_symbol]']").val(rs[0]);
                $("[name='project[decimal_places]']").val(rs[1])
              }
            });
          })
        JAVASCRIPT
      end

      def visible_class(section)
        ' active' if current_section == section
      end
    end
  end
end
