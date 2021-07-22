import React from 'react'
import PropTypes from 'prop-types'
import ProfileModal from '../components/ProfileModal'
import ProjectSetupHeader from './layouts/ProjectSetupHeader'
import * as d3 from 'd3'
import ProjectRolesController from '../controllers/project_roles_controller'

const chartColors = [
  '#0089F4',
  '#24ADFF',
  '#36BFFF',
  '#47D0FF',
  '#FB40E5',
  '#FF64FF',
  '#FF76FF',
  '#FF87FF',
  '#5037F7',
  '#745BFF',
  '#866DFF',
  '#977EFF'
]

export default class Project extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      follower: props.follower
    }

    this.arcTween = this.arcTween.bind(this)
    this.drawChart = this.drawChart.bind(this)
  }

  componentDidMount() {
    // draw piecharts
    const { chartData } = this.props.projectData
    if (chartData && chartData.length > 0) {
      this.drawChart()
    }
  }

  drawChart() {
    const { chartData } = this.props.projectData
    const sum = chartData.reduce((sub, ele) => sub + ele, 0)
    let data = chartData.map((ele, index) => ({ index: index, value: sum > 0 ? (ele / sum * 100).toFixed(2) : 0 }))

    let width = 255
    let height = 255

    let outerRadius = height / 2 - 10
    let innerRadius = outerRadius / 3

    let pie = d3.pie()
      .value((d) => { return d.value })
      .padAngle(0.02)

    let arc = d3.arc()
      .padRadius(outerRadius)
      .innerRadius(innerRadius)

    let svg = d3.select('.project-chart').append('svg')
      .attr('width', width)
      .attr('height', height)
      .append('g')
      .attr('class', 'project-chart__svg')
      .attr('transform', 'translate(' + width / 2 + ',' + height / 2 + ')')

    let centerEle = svg.append('text')
      .attr('x', 0)
      .attr('y', 5)
      .attr('font-family', 'Montserrat, sans-serif')
      .attr('font-weight', 'bold')
      .attr('font-size', 18)
      .attr('fill', '#3a3a3a')
      .attr('text-anchor', 'middle')

    svg.selectAll('path')
      .data(pie(data.slice(0, 12)))
      .enter().append('path')
      .style('fill', (d, i) => {
        return chartColors[i]
      })
      .each((d) => { d.outerRadius = outerRadius - 10 })
      .attr('d', arc)
      .on('mouseover', this.arcTween(arc, centerEle, outerRadius, 0, true))
      .on('mouseout', this.arcTween(arc, centerEle, outerRadius - 10, 150, false))
  }

  arcTween(arc, centerEle, outerRadius, delay, changeText) {
    const contributors = this.props.projectData.team
    return function(d) {
      const { layerX, layerY } = d3.event
      if (changeText) {
        centerEle.text(d.value + '%')
        d3.select('#tooltip')
          .style('left', layerX + 'px')
          .style('top', layerY + 'px')
          .style('opacity', 1)
        this.setState({tooltipContributor: contributors[d.data.index]})
      } else {
        d3.select('#tooltip')
          .style('opacity', 0)
        centerEle.text('')
      }
      d3.select(this).transition().delay(delay).attrTween('d', (d) => {
        const i = d3.interpolate(d.outerRadius, outerRadius)
        return function(t) { d.outerRadius = i(t); return arc(d) }
      })
    }.bind(this)
  }

  addProjectRole(projectId) {
    new ProjectRolesController().follow(projectId).then(response => {
      if (response.status === 200) {
        this.setState({ follower: true })
      } else if (response.status === 401) {
        window.location = '/accounts/new'
      } else {
        throw Error(response.text())
      }
    })
  }

  removeProjectRole(projectId) {
    new ProjectRolesController().unfollow(projectId).then(response => {
      if (response.status === 200) {
        this.setState({ follower: false })
      } else if (response.status === 401) {
        window.location = '/accounts/new'
      } else {
        throw Error(response.text())
      }
    })
  }

  render() {
    const { projectData, tokenData } = this.props
    const { follower } = this.state

    return <div className='project-container animated fadeIn faster'>
      <ProjectSetupHeader
        projectForHeader={this.props.projectForHeader}
        missionForHeader={this.props.missionForHeader}
        whitelabel={this.props.whitelabel}
        owner={this.props.editable}
        current='overview'
        expanded
      />

      <div className='project-award'>
        {!follower &&
          <button
            className='button project-interest__button'
            onClick={() => this.addProjectRole(projectData.id)}
          >
            Follow
          </button>
        }
        {follower &&
          <button
            className='button project-interest__button'
            onClick={() => this.removeProjectRole(projectData.id)}
          >
            Unfollow
          </button>
        }
        {projectData.displayTeam &&
          <div className='project-team'>
            <div className='project-team__container'>
              <div className='project-team__contributors-container'>
                <div className='project-team__contributors' >
                  {projectData.team.map((contributor, index) =>
                    <div key={contributor.id} className='project-team__contributor-container'>
                      <img className={(contributor.specialty && contributor.specialty.name === 'Team Leader') ? 'project-team__contributor__avatar--team-leader' : 'project-team__contributor__avatar'} style={{zIndex: projectData.team.length - index}} src={contributor.imageUrl} />
                      <div className='project-team__contributor__modal'>
                        <ProfileModal profile={contributor} />
                      </div>
                    </div>
                  )}
                </div>
                {projectData.teamSize > projectData.team.length && <div className='project-team__contributors__more'>+{projectData.teamSize - projectData.team.length}</div>}
              </div>
            </div>
          </div>
        }
      </div>

      <div className='project-description'>
        <div className='project-description__video'>
          {projectData.videoId &&
            <iframe className='project-description__video__iframe' src={`//www.youtube.com/embed/${projectData.videoId}?modestbranding=1&iv_load_policy=3&rel=0&showinfo=0&color=white&autohide=0`} frameBorder='0' />
          }
          {/* {!projectData.videoId && */}
          {/*  <img src={projectData.squareImageUrl} width="100%" /> */}
          {/* } */}
        </div>
        <div className='project-description__text'>
          <div dangerouslySetInnerHTML={{__html: projectData.descriptionHtml}} />
        </div>
      </div>

      <div className='project-award'>
        {tokenData && projectData.awardedTokens > 0 && projectData.maximumTokens > 0 &&
        <div className='project-award__progress'>
          <div className='project-award__progress__stats'>
            <div>
              Tokens awarded:
              <strong className='project-award__percent'> {projectData.tokenPercentage}</strong> — {projectData.awardedTokens} out of {projectData.maximumTokens} {tokenData.symbol}
            </div>
          </div>
          <div className='project-award__progress__bar-container'>
            <div className='project-award__progress__bar-line' />
            <div className='project-award__progress__bar-gradient' style={{width: `${projectData.tokenPercentage}`}} />
          </div>
        </div>
        }
      </div>

      {projectData.displayTeam &&
        <div className='project-team'>
          <div className='project-team__container'>
            <div className='project-team__title'>The Team</div>
            <div className='project-team__subtitle'>Great projects are the result of dozens to hundreds of individual tasks being completed with skill and care. Check out the people that have made this project special with their individual contributions.</div>

            <div className='project-chart'>
              <div id='tooltip' className='tooltip-hidden'>
                {this.state.tooltipContributor &&
                  <ProfileModal profile={this.state.tooltipContributor} />
                }
              </div>
            </div>

            <div className='project-team__contributors-container'>
              <div className='project-team__contributors' >
                {projectData.team.map((contributor, index) =>
                  <div key={contributor.id} className='project-team__contributor-container'>
                    <img className='project-team__contributor__avatar' style={{zIndex: projectData.team.length - index}} src={contributor.imageUrl} />
                    <div className='project-team__contributor__modal'>
                      <ProfileModal profile={contributor} />
                    </div>
                  </div>
                )}
              </div>
              {projectData.teamSize > projectData.team.length && <div className='project-team__contributors__more'>+{projectData.teamSize - projectData.team.length}</div>}
            </div>
          </div>
        </div>
      }

      <div className='project-interest'>
        <p className='project-interest__text'>Let the project leaders know that you are interested in the project so they can invite you to tasks that you are qualified for.</p>
        {!follower &&
          <button
            className='button project-interest__button'
            onClick={() => this.addProjectRole(projectData.id)}
          >
            Follow
          </button>
        }
        {follower &&
          <button
            className='button project-interest__button'
            onClick={() => this.removeProjectRole(projectData.id)}
          >
            Unfollow
          </button>
        }
      </div>
    </div>
  }
}

Project.propTypes = {
  projectData     : PropTypes.shape({}),
  tokenData       : PropTypes.shape({}),
  follower        : PropTypes.bool,
  csrfToken       : PropTypes.string,
  editable        : PropTypes.bool,
  whitelabel      : PropTypes.bool,
  myTasksPath     : PropTypes.string,
  editPath        : PropTypes.string,
  missionForHeader: PropTypes.object,
  projectForHeader: PropTypes.object
}

Project.defaultProps = {
  projectData     : {
    description: '',
    team       : [],
    teamSize   : 0,
    chartData  : [],
    stats      : {},
    displayTeam: true
  },
  missionData        : null,
  tokenData          : null,
  follower           : false,
  csrfToken          : '',
  editable           : true,
  contributorsPath   : '',
  awardsPath         : '',
  awardTypesPath     : '',
  myTasksPath        : '',
  editPath           : null,
  missionForHeader   : null,
  projectForHeader   : null
}
