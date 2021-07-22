import React from 'react'
import { mount } from 'enzyme'
import ProjectForm from 'components/ProjectForm'

describe('ProjectForm', () => {
  it('renders correctly without props', () => {
    const wrapper = mount(<ProjectForm />)

    expect(wrapper).toMatchSnapshot()

    expect(wrapper.exists('.project-form')).toBe(true)
    expect(wrapper.exists('ButtonBorder[value="cancel"]')).toBe(true)
    expect(wrapper.exists('ButtonBorder[value="create"]')).toBe(true)
    expect(wrapper.exists('Button[value="create & close"]')).toBe(true)
    expect(wrapper.exists('.project-form--message')).toBe(false)
    expect(wrapper.exists('.project-form--form')).toBe(true)
    expect(wrapper.exists('#project-form--form')).toBe(true)

    expect(wrapper.exists(
      'InputFieldDropdown[title="mission"][name="project[mission_id]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldDropdown[title="token"][name="project[token_id]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldWhiteDark[title="title"][required][name="project[title]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldDescription[title="description"][required][name="project[description]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldWhiteDark[title="narrated video overview"][recommended][name="project[video_url]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldWhiteDark[title="total budget"][name="project[maximum_tokens]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldDropdown[title="project visibility"][required][name="project[visibility]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldWhiteDark[title="project url"][required][name="project[url]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldDropdown[title="awards visibility"][required][name="project[require_confidentiality]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'InputFieldUploadFile[title="project image"][name="project[square_image]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'input[type="hidden"][name="project[long_id]"]'
    )).toBe(true)

    expect(wrapper.exists(
      'input[type="hidden"][name="authenticity_token"]'
    )).toBe(true)

    expect(wrapper.exists(
      '.project-form--form--channels--empty'
    )).toBe(true)

    expect(wrapper.exists(
      '.project-form--form--channels--discord-link'
    )).toBe(false)
  })

  it('renders correctly with tokens', () => {
    const tokens = {
      'token1': 1,
      'token2': 2
    }
    const wrapper = mount(<ProjectForm tokens={tokens} />)

    expect(wrapper.find(
      'InputFieldDropdown[title="token"][name="project[token_id]"]'
    ).props().value).toBe('1')

    expect(wrapper.find(
      'InputFieldDropdown[title="token"][name="project[token_id]"]'
    ).props().selectEntries).toEqual(Object.entries(tokens))
  })

  it('renders correctly with missions', () => {
    const missions = {
      'mission1': 1,
      'mission2': 2
    }
    const wrapper = mount(<ProjectForm missions={missions} />)

    expect(wrapper.find(
      'InputFieldDropdown[title="mission"][name="project[mission_id]"]'
    ).props().value).toBe('1')

    expect(wrapper.find(
      'InputFieldDropdown[title="mission"][name="project[mission_id]"]'
    ).props().selectEntries).toEqual(Object.entries(missions))
  })

  it('renders correctly with visibilities', () => {
    const visibilities = [
      'member_unlisted',
      'member',
      'archived',
      'public_listed',
      'public_unlisted'
    ]
    const wrapper = mount(<ProjectForm visibilities={visibilities} />)

    expect(wrapper.find(
      'InputFieldDropdown[title="project visibility"][required][name="project[visibility]"]'
    ).props().value).toBe('member_unlisted')

    expect(wrapper.find(
      'InputFieldDropdown[title="project visibility"][required][name="project[visibility]"]'
    ).props().selectEntries).toEqual([
      ['Logged in team member via unlisted URL', 'member_unlisted'],
      ['Logged In Team Members (Project Slack/Discord channels, Admins, Emailed Award Recipients)', 'member'],
      ['Archived (visible only to me)', 'archived'],
      ['Public', 'public_listed'],
      ['Unlisted URL (no login required)', 'public_unlisted']
    ])
  })

  it('renders discord auth link when supplied with one', () => {
    const wrapper = mount(<ProjectForm discordBotUrl='http://null' />)

    expect(wrapper.exists(
      '.project-form--form--channels--discord-link'
    )).toBe(true)
  })

  it('hides channels section if Discord and Slack disabled', () => {
    const wrapper = mount(<ProjectForm discordEnabled={false} slackEnabled={false}  />)

    expect(wrapper.contains(<h2>Communication Channels</h2>)).toEqual(false)
  })

  it('shows channels section if Discord enabled', () => {
    const wrapper = mount(<ProjectForm discordEnabled slackEnabled={false}  />)

    expect(wrapper.contains(<h2>Communication Channels</h2>)).toEqual(true)
  })

  it('shows channels section if Slack enabled', () => {
    const wrapper = mount(<ProjectForm discordEnabled={false} slackEnabled  />)

    expect(wrapper.contains(<h2>Communication Channels</h2>)).toEqual(true)
  })

  it('shows channels section if Discord and Slack enabled', () => {
    const wrapper = mount(<ProjectForm discordEnabled slackEnabled  />)

    expect(wrapper.contains(<h2>Communication Channels</h2>)).toEqual(true)
  })

  it('renders correctly with teams', () => {
    const teams = [
      {
        'team'    : 'team1Name',
        'teamId'  : 'team1Id',
        'channels': [
          {
            'channel'  : 'ch1Name',
            'channelId': 'ch1Id'
          },
          {
            'channel'  : 'ch2Name',
            'channelId': 'ch2Id'
          }
        ]
      },
      {
        'team'    : 'team2Name',
        'teamId'  : 'team2Id',
        'channels': [
          {
            'channel'  : 'ch3Name',
            'channelId': 'ch3Id'
          },
          {
            'channel'  : 'ch4Name',
            'channelId': 'ch4Id'
          }
        ]
      }
    ]
    const wrapper = mount(<ProjectForm teams={teams} />)

    wrapper.find('.project-form--form--channels--add').simulate('click')

    expect(wrapper.find(
      'input[type="hidden"][name="project[channels_attributes][1000000][id]"]'
    ).props().value).toBe('')

    expect(wrapper.find(
      'InputFieldDropdownHalfed[title="team or guild"][required][name="project[channels_attributes][1000000][team_id]"]'
    ).props().value).toBe('team1Id')
    expect(wrapper.find(
      'InputFieldDropdownHalfed[title="team or guild"][required][name="project[channels_attributes][1000000][team_id]"]'
    ).props().selectEntries).toEqual([
      ['team1Name', 'team1Id'],
      ['team2Name', 'team2Id']
    ])

    expect(wrapper.find(
      'InputFieldDropdownHalfed[title="channel"][required][name="project[channels_attributes][1000000][channel_id]"]'
    ).props().value).toBe('ch1Id')
    expect(wrapper.find(
      'InputFieldDropdownHalfed[title="channel"][required][name="project[channels_attributes][1000000][channel_id]"]'
    ).props().selectEntries).toEqual([
      ['ch1Name', 'ch1Id'],
      ['ch2Name', 'ch2Id']
    ])

    wrapper.find('.project-form--form--channels--channel--del').at(0).simulate('click')
    expect(wrapper.exists('input[type="hidden"][name="project[channels_attributes][1000000][id]"]')).toBe(true)
    expect(wrapper.exists('input[type="hidden"][name="project[channels_attributes][1000000][_destroy]"]')).toBe(false)
    expect(wrapper.exists('InputFieldDropdownHalfed[title="team or guild"][required][name="project[channels_attributes][1000000][team_id]"]')).toBe(false)
    expect(wrapper.exists('InputFieldDropdownHalfed[title="team or guild"][required][name="project[channels_attributes][1000000][channel_id]"]')).toBe(false)
  })

  it('renders correctly with project', () => {
    const project = {
      'id'                     : 2,
      'missionId'              : 2,
      'tokenId'                : 2,
      'title'                  : 'title',
      'description'            : 'desc',
      'videoUrl'               : 'https://youtube.com/',
      'maximumTokens'          : '1000',
      'visibility'             : 'archived',
      'exclusive_contributions': false,
      'confidentiality'        : false,
      'channels'               : [
        {
          'channelId': 'ch1Id',
          'teamId'   : 'team1Id',
          'id'       : 1
        },
        {
          'channelId': 'ch2Id',
          'teamId'   : 'team1Id',
          'id'       : 2
        }
      ],
      'url'                   : 'https://www.comakery.com/p/test',
      'longId'                : '123',
      'requireConfidentiality': false,
      'legalProjectOwner'     : 'CoMakery',
      'squareImageUrl'        : '/s.png',
    }
    const visibilities = [
      'member_unlisted',
      'member',
      'archived',
      'public_listed',
      'public_unlisted'
    ]
    const missions = {
      'mission1': 1,
      'mission2': 2
    }
    const tokens = {
      'token1': 1,
      'token2': 2
    }
    const teams = [
      {
        'team'    : 'team1Name',
        'teamId'  : 'team1Id',
        'channels': [
          {
            'channel'  : 'ch1Name',
            'channelId': 'ch1Id'
          },
          {
            'channel'  : 'ch2Name',
            'channelId': 'ch2Id'
          }
        ]
      }
    ]
    const wrapper = mount(<ProjectForm
      project={project}
      tokens={tokens}
      missions={missions}
      visibilities={visibilities}
      teams={teams}
    />)

    expect(wrapper.find(
      'InputFieldDropdown[title="mission"][name="project[mission_id]"]'
    ).props().value).toBe('2')

    expect(wrapper.find(
      'InputFieldDropdown[title="token"][name="project[token_id]"]'
    ).props().value).toBe('2')

    expect(wrapper.find(
      'InputFieldWhiteDark[title="title"][required][name="project[title]"]'
    ).props().value).toBe('title')

    expect(wrapper.find(
      'InputFieldDescription[title="description"][required][name="project[description]"]'
    ).props().value).toBe('desc')

    expect(wrapper.find(
      'InputFieldWhiteDark[title="narrated video overview"][recommended][name="project[video_url]"]'
    ).props().value).toBe('https://youtube.com/')

    expect(wrapper.find(
      'InputFieldWhiteDark[title="total budget"][name="project[maximum_tokens]"]'
    ).props().value).toBe('1000')

    expect(wrapper.find(
      'InputFieldDropdown[title="project visibility"][required][name="project[visibility]"]'
    ).props().value).toBe('archived')

    expect(wrapper.find(
      'InputFieldWhiteDark[title="project url"][required][name="project[url]"]'
    ).props().value).toBe('https://www.comakery.com/p/test')

    expect(wrapper.find(
      'InputFieldDropdown[title="awards visibility"][required][name="project[require_confidentiality]"]'
    ).props().value).toBe('false')

    expect(wrapper.find(
      'InputFieldUploadFile[title="project image"][name="project[square_image]"]'
    ).props().imgPreviewUrl).toBe('/s.png')

    expect(wrapper.find(
      'input[type="hidden"][name="project[long_id]"]'
    ).props().value).toBe('123')

    expect(wrapper.find(
      'input[type="hidden"][name="project[channels_attributes][1][id]"]'
    ).props().value).toBe(1)

    wrapper.find('.project-form--form--channels--channel--del').at(0).simulate('click')
    expect(wrapper.find(
      'input[type="hidden"][name="project[channels_attributes][1][_destroy]"]'
    ).props().value).toBe('1')
    expect(wrapper.exists('input[type="hidden"][name="project[channels_attributes][1][id]"]')).toBe(true)

    expect(wrapper.exists('input[type="hidden"][name="project[channels_attributes][2][id]"]')).toBe(true)
  })

  it('renders correctly with csrfToken', () => {
    const wrapper = mount(<ProjectForm csrfToken='test' />)

    expect(wrapper.find(
      'input[type="hidden"][name="authenticity_token"]'
    ).props().value).toBe('test')
  })

  it('uses formUrl', () => {
    const wrapper = mount(<ProjectForm formUrl='/test' />)

    expect(wrapper.state('formUrl')).toBe('/test')
  })

  it('uses formAction', () => {
    const wrapper = mount(<ProjectForm formAction='PUT' />)

    expect(wrapper.state('formAction')).toBe('PUT')
  })

  it('uses urlOnSuccess', () => {
    const wrapper = mount(<ProjectForm urlOnSuccess='/test' />)

    expect(wrapper.props().urlOnSuccess).toBe('/test')
  })

  it('displays messages', () => {
    const wrapper = mount(<ProjectForm />)

    wrapper.setState({
      flashMessages: [
        {
          'severity': 'notice',
          'text'    : 'notice text'
        },
        {
          'severity': 'warning',
          'text'    : 'warning text'
        },
        {
          'severity': 'error',
          'text'    : 'error text'
        }
      ]
    })

    wrapper.update()

    expect(wrapper.exists('Flash')).toBe(true)
  })

  it('displays errors', () => {
    const wrapper = mount(<ProjectForm />)

    wrapper.setState({
      errors: {
        'project[title]'       : ['title error'],
        'project[mission_id]'  : ['mission_id error'],
        'project[square_image]': ['square_image error']
      }
    })

    wrapper.update()

    expect(
      wrapper.find('InputFieldWhiteDark[title="title"][required][name="project[title]"] .input-field--error').html()
    ).toContain('title error')

    expect(
      wrapper.find('InputFieldDropdown[title="mission"][name="project[mission_id]"] .input-field--error').html()
    ).toContain('mission_id error')

    expect(
      wrapper.find('InputFieldUploadFile[title="project image"][name="project[square_image]"] .input-field--error').html()
    ).toContain('square_image error')
  })
})
