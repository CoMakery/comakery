import React from 'react'
import PropTypes from 'prop-types'
import ProjectSetup from './layouts/ProjectSetup'
import { fetch as fetchPolyfill } from 'whatwg-fetch'
import { toSnakeCase } from './utils'
import InputFieldUploadFile from './styleguide/InputFieldUploadFile'
import Button from './styleguide/Button'
import ButtonBorder from './styleguide/ButtonBorder'
import Flash from './layouts/Flash'
import InputFieldDropdown from './styleguide/InputFieldDropdown'
import InputFieldDropdownHalfed from './styleguide/InputFieldDropdownHalfed'
import InputFieldWhiteDark from './styleguide/InputFieldWhiteDark'
import InputFieldDescription from './styleguide/InputFieldDescription'
import Icon from './styleguide/Icon'

class ProjectForm extends React.Component {
  constructor(props) {
    super(props)

    this.errorAdd = this.errorAdd.bind(this)
    this.errorRemove = this.errorRemove.bind(this)
    this.disable = this.disable.bind(this)
    this.enable = this.enable.bind(this)
    this.addChannel = this.addChannel.bind(this)
    this.destroyChannel = this.destroyChannel.bind(this)
    this.handleChannelFieldChange = this.handleChannelFieldChange.bind(this)
    this.handleSubmit = this.handleSubmit.bind(this)
    this.handleFieldChange = this.handleFieldChange.bind(this)
    this.verifyImgSize = this.verifyImgSize.bind(this)

    this.squareImgInputRef = React.createRef()

    let awardVisibilitiesPretty = {
      'Only admins can see list of rewards': 'true',
      'Show all awards & contributions'    : 'false'
    }

    let visibilitiesPretty = {}
    this.props.visibilities.forEach(v => {
      switch (v) {
        case 'member':
          visibilitiesPretty['Logged In Team Members (Project Slack/Discord channels, Admins, Emailed Award Recipients)'] = v
          break
        case 'public_listed':
          visibilitiesPretty.Public = v
          break
        case 'member_unlisted':
          visibilitiesPretty['Logged in team member via unlisted URL'] = v
          break
        case 'public_unlisted':
          visibilitiesPretty['Unlisted URL (no login required)'] = v
          break
        case 'archived':
          visibilitiesPretty['Archived (visible only to me)'] = v
          break
        default:
          visibilitiesPretty[v] = v
      }
    })

    this.state = {
      flashMessages                     : [],
      errors                            : {},
      disabled                          : {},
      formAction                        : this.props.formAction,
      formUrl                           : this.props.formUrl,
      closeOnSuccess                    : false,
      awardVisibilitiesPretty           : awardVisibilitiesPretty,
      visibilitiesPretty                : visibilitiesPretty,
      discordUrlActivated               : false,
      id                                : this.props.project.id || null,
      'project[mission_id]'             : this.props.project.missionId || Object.values(this.props.missions)[0],
      'project[token_id]'               : this.props.project.tokenId || Object.values(this.props.tokens)[0],
      'project[visibility]'             : this.props.project.visibility || Object.values(visibilitiesPretty)[0],
      'project[require_confidentiality]': (this.props.project.requireConfidentiality === true || this.props.project.requireConfidentiality === null) ? 'true' : 'false',
      'project[url]'                    : this.props.project.url || '',
      'project[title]'                  : this.props.project.title || '',
      'project[description]'            : this.props.project.description || '',
      'project[maximum_tokens]'         : this.props.project.maximumTokens || '',
      'project[video_url]'              : this.props.project.videoUrl || '',
      'project[github_url]'             : this.props.project.githubUrl || '',
      'project[documentation_url]'      : this.props.project.documentationUrl || '',
      'project[getting_started_url]'    : this.props.project.gettingStartedUrl || '',
      'project[governance_url]'         : this.props.project.governanceUrl || '',
      'project[funding_url]'            : this.props.project.fundingUrl || '',
      'project[video_conference_url]'   : this.props.project.videoConferenceUrl || '',
      'project[legal_project_owner]'    : this.props.project.legalProjectOwner || '',
      'project[exclusive_contributions]': this.props.project.exclusiveContributions ? 'true' : 'false',
      'project[confidentiality]'        : this.props.project.confidentiality ? 'true' : 'false',
      'project[display_team]'           : this.props.project.displayTeam ? 'true' : 'false',
      'project[channels]'               : this.props.project.channels || []
    }
  }

  errorAdd(key, e) {
    let errors = this.state.errors

    if (errors.hasOwnProperty(key)) {
      if (errors[key].includes(e)) {
        return
      }

      this.setState({
        errors: Object.assign({}, errors, {[key]: [...errors[key], e]})
      })
    } else {
      this.setState({
        errors: Object.assign({}, errors, {[key]: Object.assign([], errors[key], [e])})
      })
    }
  }

  errorRemove(key, e) {
    let errors = this.state.errors

    if (errors[key] === undefined) {
      return
    }

    let index = errors[key].indexOf(e)

    errors[key].splice(index, 1)

    if (errors[key].length === 0) {
      delete errors[key]
    }

    this.setState({
      errors: errors
    })
  }

  disable(a) {
    let d = this.state.disabled
    a.forEach(n => (d = Object.assign({}, d, {[n]: true})))
    this.setState({
      disabled: d
    })
  }

  enable(a) {
    let d = this.state.disabled
    a.forEach(n => delete d[n])
    this.setState({
      disabled: d
    })
  }

  addChannel() {
    this.setState(state => ({
      'project[channels]': state['project[channels]'].concat({
        channelId: this.props.teams.find(t => t.teamId === this.props.teams[0].teamId).channels[0].channelId,
        teamId   : this.props.teams[0].teamId,
        id       : `${state['project[channels]'].length + 1000000}`,
        new      : true
      })
    }))
  }

  handleChannelFieldChange(event, i) {
    let channels = this.state['project[channels]']

    if (event.target.name.match(/channel_id/)) {
      channels[i] = {
        channelId: event.target.value,
        teamId   : channels[i].teamId,
        id       : channels[i].id,
        new      : channels[i].new
      }
    } else {
      channels[i] = {
        channelId: this.props.teams.find(t => t.teamId === event.target.value).channels[0].channelId,
        teamId   : event.target.value,
        id       : channels[i].id,
        new      : channels[i].new
      }
    }

    this.setState({
      'project[channels]': channels
    })
  }

  destroyChannel(event, i) {
    let channels = this.state['project[channels]']

    channels[i] = {
      id     : channels[i].id,
      destroy: true,
      new    : channels[i].new
    }

    this.setState({
      'project[channels]': channels
    })
  }

  verifyImgSize(event) {
    let file = event.target.files[0]

    if (file && file.size) {
      const errorMessage = 'Image size must me less then 2 megabytes'
      const fileSizeMb = file.size / Math.pow(1024, 2)
      const maxSize = 2

      if (fileSizeMb > maxSize) {
        this.errorAdd(event.target.name, errorMessage)
      } else {
        this.errorRemove(event.target.name, errorMessage)
      }
    }
  }

  handleFieldChange(event) {
    const errorMessage = 'Please provide the correct value'

    this.setState({ [event.target.name]: event.target.value })

    if (!event.target.checkValidity()) {
      this.errorAdd(event.target.name, errorMessage)
      return
    } else {
      this.errorRemove(event.target.name, errorMessage)
    }

    if (event.target.value === '') {
      return
    }
  }

  handleSubmit(event) {
    event.preventDefault()

    this.disable(['project[submit]', 'project[submit_and_close]'])

    if (!event.target.checkValidity() || Object.keys(this.state.errors).length > 0) {
      this.enable(['project[submit]', 'project[submit_and_close]'])
      return
    }

    const formData = new FormData(event.target)

    fetchPolyfill(this.state.formUrl, {
      credentials: 'same-origin',
      method     : this.state.formAction,
      body       : formData,
      headers    : {
        'X-Key-Inflection': 'snake'
      }
    }).then(response => {
      response.json().then(data => {
        if (response.status === 200) {
          if (this.state.closeOnSuccess) {
            window.location = `${window.location.origin}/projects/${data.id}/batches`
          } else {
            if (this.state.formAction === 'POST') {
              this.setState(state => ({
                formAction         : 'PUT',
                formUrl            : `/projects/${data.id}`,
                id                 : data.id,
                'project[channels]': data.props.project.channels || [],
                flashMessages      : state.flashMessages.concat([{'severity': 'notice', 'text': 'Project Created'}])
              }))
              history.replaceState(
                {},
                document.title,
                `${window.location.origin}/projects/${data.id}/edit`
              )
            } else {
              this.setState(state => ({
                'project[channels]': data.props.project.channels || [],
                flashMessages      : state.flashMessages.concat([{'severity': 'notice', 'text': 'Project Updated'}])
              }))
            }
            this.enable(['project[submit]', 'project[submit_and_close]'])
          }
        } else {
          this.setState(state => ({
            errors: Object.entries(data.errors).reduce((obj, [k, v]) => ({ ...obj, [toSnakeCase(k)]: [v] }), {}),
            flashMessages: state.flashMessages.concat([{'severity': 'error', 'text': data.message}])
          }))

          this.enable(['project[submit]', 'project[submit_and_close]'])
        }
      })
    })
  }

  goBack() {
    typeof window === 'undefined' ? null : window.history.back()
  }

  render() {
    return (
      <React.Fragment>
        <ProjectSetup
          className='project-form'
          projectForHeader={this.props.projectForHeader}
          missionForHeader={!this.props.isWhitelabel && this.props.missionForHeader}
          owner
          current='form'
          subfooter={
            <React.Fragment>
              <Button
                value={this.state.formAction === 'POST' ? 'create & close' : 'save & close'}
                type='submit'
                form='project-form--form'
                disabled={this.state.disabled['project[submit_and_close]']}
                onClick={() => this.setState({closeOnSuccess: true})}
              />
              <ButtonBorder
                value={this.state.formAction === 'POST' ? 'create' : 'save'}
                type='submit'
                form='project-form--form'
                disabled={this.state.disabled['project[submit]']}
                onClick={() => this.setState({closeOnSuccess: false})}
              />
              <ButtonBorder
                value='cancel'
                onClick={this.goBack}
              />
            </React.Fragment>
          }
        >
          <Flash messages={this.state.flashMessages} />

          <form className='project-form--form' id='project-form--form' onSubmit={this.handleSubmit}>
            { !this.props.isWhitelabel &&
              <InputFieldDropdown
                title='mission'
                name='project[mission_id]'
                value={this.state['project[mission_id]'] ? this.state['project[mission_id]'].toString() : null}
                errors={this.state.errors['project[mission_id]']}
                disabled={this.state.disabled['project[mission_id]']}
                eventHandler={this.handleFieldChange}
                selectEntries={Object.entries(this.props.missions)}
                symbolLimit={0}
              />
            }

            <InputFieldWhiteDark
              title='title'
              required
              name='project[title]'
              value={this.state['project[title]']}
              errors={this.state.errors['project[title]']}
              placeholder='Provide a name for the project'
              eventHandler={this.handleFieldChange}
              symbolLimit={100}
            />

            <InputFieldDescription
              title='description'
              required
              name='project[description]'
              value={this.state['project[description]']}
              errors={this.state.errors['project[description]']}
              placeholder='Explain the outline and goal of the project, and why people should be excited about helping to execute the vision'
              eventHandler={this.handleFieldChange}
              symbolLimit={20000}
            />

            <InputFieldUploadFile
              title='project image'
              name='project[square_image]'
              eventHandler={this.verifyImgSize}
              errors={this.state.errors['project[square_image]']}
              imgPreviewUrl={this.props.project.squareImageUrl}
              imgPreviewDimensions='150x100'
              imgRequirements='The best image size is 1200px x 800px'
              imgInputRef={this.squareImgInputRef}
            />

            <input
              type='hidden'
              name='project[long_id]'
              value={this.props.project.longId}
              readOnly
            />

            <input
              type='hidden'
              name='authenticity_token'
              value={this.props.csrfToken}
              readOnly
            />

            <h2>Links</h2>
            <InputFieldWhiteDark
              title='narrated video overview'
              recommended
              name='project[video_url]'
              value={this.state['project[video_url]']}
              errors={this.state.errors['project[video_url]']}
              placeholder='Link to a YouTube or Vimeo video describing the project'
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />
            <InputFieldWhiteDark
              title='getting started url'
              recommended
              name='project[getting_started_url]'
              value={this.state['project[getting_started_url]']}
              errors={this.state.errors['project[getting_started_url]']}
              placeholder='Link to how to get started with your project'
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />
            <InputFieldWhiteDark
              title='github project url'
              name='project[github_url]'
              value={this.state['project[github_url]']}
              errors={this.state.errors['project[github_url]']}
              placeholder='Link to a GitHub repository'
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />
            <InputFieldWhiteDark
              title='documentation url'
              name='project[documentation_url]'
              value={this.state['project[documentation_url]']}
              errors={this.state.errors['project[documentation_url]']}
              placeholder='Link to your projects documentation'
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />
            <InputFieldWhiteDark
              title='governance url'
              name='project[governance_url]'
              value={this.state['project[governance_url]']}
              errors={this.state.errors['project[governance_url]']}
              placeholder='Link to your project governance (e.g. Loomio.com or DAOstack.io)'
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />
            <InputFieldWhiteDark
              title='funding url'
              name='project[funding_url]'
              value={this.state['project[funding_url]']}
              errors={this.state.errors['project[funding_url]']}
              placeholder='Link to your funding (e.g. Open Collective or a DAO funding url)'
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />
            <InputFieldWhiteDark
              title='video conference url'
              name='project[video_conference_url]'
              value={this.state['project[video_conference_url]']}
              errors={this.state.errors['project[video_conference_url]']}
              placeholder='Link to your teams video conference url'
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />
            <h2>Tokens</h2>

            <InputFieldDropdown
              title='token'
              name='project[token_id]'
              value={this.state['project[token_id]'] ? this.state['project[token_id]'].toString() : null}
              errors={this.state.errors['project[token_id]']}
              disabled={this.state.disabled['project[token_id]']}
              eventHandler={this.handleFieldChange}
              selectEntries={Object.entries(this.props.tokens)}
              symbolLimit={0}
            />

            <InputFieldWhiteDark
              title='total budget'
              name='project[maximum_tokens]'
              value={this.state['project[maximum_tokens]'] ? this.state['project[maximum_tokens]'].toString() : ''}
              errors={this.state.errors['project[maximum_tokens]']}
              placeholder='Provide the budget for completing the entire project'
              pattern='\d+'
              eventHandler={this.handleFieldChange}
              type='number'
              min='0'
              step={`${1.0 / (10 ** (this.props.decimalPlaces.find(t => t.id.toString() === this.state['project[token_id]'].toString()) ? this.props.decimalPlaces.find(t => t.id.toString() === this.state['project[token_id]'].toString()).decimal_places : 0))}`}
              symbolLimit={0}
            />
            { !this.props.isWhitelabel && (this.props.discordEnabled || this.props.slackEnabled) &&
            <React.Fragment>
              <h2>Communication Channels</h2>

              {this.props.teams.length > 0 && this.state['project[channels]'].map((c, i) =>
                <div className='project-form--form--channels--channel' key={i}>
                  <input
                    type='hidden'
                    name={`project[channels_attributes][${c.id}][id]`}
                    value={c.new ? '' : c.id}
                  />

                  {!c.destroy && !c.new &&
                  <React.Fragment>
                    <InputFieldWhiteDark
                      required
                      disabled
                      className='project-form--form--channels--channel--select'
                      title='channel'
                      name={`project[channels_attributes][${c.id}][channel_id]`}
                      value={c.nameWithProvider}
                      symbolLimit={0}
                      style={{'opacity': '0.7', 'cursor': 'not-allowed'}}
                    />
                    <div className='project-form--form--channels--channel--del' onClick={(e) => this.destroyChannel(e, i)}>
                      <Icon name='iconTrash.svg' />
                    </div>
                  </React.Fragment>
                  }

                  {!c.destroy && c.new &&
                  <React.Fragment>
                    <InputFieldDropdownHalfed
                      required
                      className='project-form--form--channels--channel--select'
                      title='team or guild'
                      name={`project[channels_attributes][${c.id}][team_id]`}
                      value={this.state['project[channels]'][i].teamId}
                      eventHandler={(e) => this.handleChannelFieldChange(e, i)}
                      selectEntries={this.props.teams.map(t => [t.team, t.teamId])}
                    />
                    <InputFieldDropdownHalfed
                      required
                      className='project-form--form--channels--channel--select'
                      title='channel'
                      name={`project[channels_attributes][${c.id}][channel_id]`}
                      value={this.state['project[channels]'][i].channelId}
                      eventHandler={(e) => this.handleChannelFieldChange(e, i)}
                      selectEntries={c.teamId && this.props.teams.find(t => t.teamId === c.teamId) ? this.props.teams.find(t => t.teamId === c.teamId).channels.map(ch => [ch.channel, ch.channelId]) : []}
                    />
                    <div className='project-form--form--channels--channel--del' onClick={(e) => this.destroyChannel(e, i)}>
                      <Icon name='iconTrash.svg' />
                    </div>
                  </React.Fragment>
                  }

                  {c.destroy && !c.new &&
                  <input
                    type='hidden'
                    name={`project[channels_attributes][${c.id}][_destroy]`}
                    value='1'
                  />
                  }
                </div>
              )}

              {this.props.teams.length > 0 &&
              <div className='project-form--form--channels--add' onClick={this.addChannel}>
                Add Channel +
              </div>
              }

              {this.props.discordBotUrl &&
              <div className='project-form--form--channels--discord-link'>
                {!this.state.discordUrlActivated &&
                <a target='_blank' href={this.props.discordBotUrl} onClick={() => this.setState({discordUrlActivated: true})}>
                  Allow Access to Discord Channels →
                </a>
                }
                {this.state.discordUrlActivated &&
                <a href=''>
                  Refresh the page after Discord access is confirmed ↻
                </a>
                }
              </div>
              }

              {this.props.teams.length === 0 && !this.props.discordBotUrl &&
              <div className='project-form--form--channels--empty'>
                Start adding channels by signing in with{ [this.props.slackEnabled ? 'Slack' : null, this.props.discordEnabled ? 'Discord' : null].filter((obj) => obj).join(' or ') }
              </div>
              }
            </React.Fragment>
            }

            <h2>Permissions & Visibility</h2>
            <InputFieldDropdown
              title='awards visibility'
              required
              name='project[require_confidentiality]'
              value={this.state['project[require_confidentiality]']}
              errors={this.state.errors['project[require_confidentiality]']}
              disabled={this.state.disabled['project[require_confidentiality]']}
              eventHandler={this.handleFieldChange}
              selectEntries={Object.entries(this.state.awardVisibilitiesPretty)}
              symbolLimit={0}
            />

            <InputFieldDropdown
              title='display team on project page'
              required
              name='project[display_team]'
              value={this.state['project[display_team]']}
              errors={this.state.errors['project[displayTeam]']}
              disabled={this.state.disabled['project[display_team]']}
              eventHandler={this.handleFieldChange}
              selectEntries={Object.entries({'Yes': 'true', 'No': 'false'})}
              symbolLimit={0}
            />

            <InputFieldDropdown
              title='project visibility'
              required
              name='project[visibility]'
              value={this.state['project[visibility]']}
              errors={this.state.errors['project[visibility]']}
              disabled={this.state.disabled['project[visibility]']}
              eventHandler={this.handleFieldChange}
              selectEntries={Object.entries(this.state.visibilitiesPretty)}
              symbolLimit={0}
            />

            <InputFieldWhiteDark
              title='project url'
              required
              readOnly
              copyOnClick
              name='project[url]'
              value={this.state['project[url]']}
              errors={this.state.errors['project[url]']}
              eventHandler={this.handleFieldChange}
              symbolLimit={0}
            />

            {/* <div className="project-form--form--terms--header"> */}
            {/*  TERMS & CONDITIONS */}
            {/* </div> */}

            {/* <div className="project-form--form--terms--content"> */}
            {/*  <InputFieldInline */}
            {/*    required */}
            {/*    readOnly={this.props.termsReadonly} */}
            {/*    name="project[legal_project_owner]" */}
            {/*    value={this.state['project[legal_project_owner]']} */}
            {/*    errors={this.state.errors['project[legalProjectOwner]']} */}
            {/*    placeholder="Provide a legal entity or individual owner's name" */}
            {/*    eventHandler={this.handleFieldChange} */}
            {/*  /> */}

            {/*  { !this.props.isWhitelabel && */}
            {/*    <React.Fragment> */}
            {/*      ("You", the "Project Owner") agree to the <a target="_blank" href={this.props.licenseUrl}>Comakery Contribution License</a> */}
            {/*      <br /> */}

            {/*      You agree that for this Project, Contributions are <InputFieldDropdownInline */}
            {/*        required */}
            {/*        disabled={this.props.termsReadonly} */}
            {/*        name="project[exclusive_contributions]" */}
            {/*        value={this.state['project[exclusive_contributions]']} */}
            {/*        errors={this.state.errors['project[exclusiveContributions]']} */}
            {/*        eventHandler={this.handleFieldChange} */}
            {/*        selectEntries={Object.entries({ */}
            {/*          'Exclusive'    : 'true', */}
            {/*          'Not Exclusive': 'false' */}
            {/*        })} */}
            {/*      /> */}
            {/*      <br /> */}

            {/*      Project confidentiality and business confidentiality are <InputFieldDropdownInline */}
            {/*        required */}
            {/*        disabled={this.props.termsReadonly} */}
            {/*        name="project[confidentiality]" */}
            {/*        value={this.state['project[confidentiality]']} */}
            {/*        errors={this.state.errors['project[confidentiality]']} */}
            {/*        eventHandler={this.handleFieldChange} */}
            {/*        selectEntries={Object.entries({ */}
            {/*          'Required'    : 'true', */}
            {/*          'Not Required': 'false' */}
            {/*        })} */}
            {/*      /> and at the time that you indicate a Task is complete you agree to pay the Contributor the Award for the Task. */}
            {/*      <br /> */}

            {/*      By {this.state.formAction === 'POST' ? 'creating this Project (clicking CREATE & CLOSE or CREATE)' : 'updating this Project (clicking SAVE & CLOSE or SAVE)'}, you agree to these Terms & Conditions. */}
            {/*      <br /> */}

            {/*      You may modify these Terms & Conditions until the first Project Task has been started by a Contributor. */}
            {/*    </React.Fragment> */}
            {/*  } */}
            {/* </div> */}

          </form>
        </ProjectSetup>
      </React.Fragment>
    )
  }
}

ProjectForm.propTypes = {
  project         : PropTypes.object.isRequired,
  tokens          : PropTypes.object.isRequired,
  missions        : PropTypes.object.isRequired,
  decimalPlaces   : PropTypes.array.isRequired,
  visibilities    : PropTypes.array.isRequired,
  teams           : PropTypes.array.isRequired,
  discordBotUrl   : PropTypes.string,
  licenseUrl      : PropTypes.string.isRequired,
  termsReadonly   : PropTypes.bool.isRequired,
  formUrl         : PropTypes.string.isRequired,
  formAction      : PropTypes.string.isRequired,
  csrfToken       : PropTypes.string.isRequired,
  missionForHeader: PropTypes.object,
  projectForHeader: PropTypes.object,
  isWhitelabel    : PropTypes.bool.isRequired,
  discordEnabled  : PropTypes.bool.isRequired,
  slackEnabled    : PropTypes.bool.isRequired
}
ProjectForm.defaultProps = {
  project         : {'default': '_'},
  tokens          : {'default': '_'},
  missions        : {'default': '_'},
  decimalPlaces   : [],
  visibilities    : [],
  teams           : [],
  discordBotUrl   : null,
  licenseUrl      : '/',
  termsReadonly   : false,
  formUrl         : '/',
  formAction      : 'POST',
  csrfToken       : '00',
  missionForHeader: null,
  projectForHeader: null,
  isWhitelabel    : false,
  discordEnabled  : true,
  slackEnabled    : true
}
export default ProjectForm
