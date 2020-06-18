import React from 'react'
import PropTypes from 'prop-types'
import ProfileModal from '../components/ProfileModal'
import ProjectSetupHeader from './layouts/ProjectSetupHeader'
import MyTask from './MyTask'
import d3 from 'd3/d3'
import styled from 'styled-components'
import InterestsController from '../controllers/interests_controller'

const Tasks = styled.div`
  padding: 15px;
  max-width: 680px;
  margin: auto;
`

const TasksTitle = styled.div`
  margin: 40px;

  h2 {
    font-family: Montserrat;
    font-size: 24px;
    font-weight: 900;
    font-style: normal;
    font-stretch: normal;
    line-height: normal;
    letter-spacing: normal;
    text-align: center;
    text-transform: uppercase;
    color: #3a3a3a;
  }

  p {
    font-family: Georgia;
    font-size: 16px;
    font-weight: normal;
    font-style: normal;
    font-stretch: normal;
    line-height: 1.63;
    letter-spacing: normal;
    text-align: center;
    color: #4a4a4a;
  }
`

const TasksSpecialty = styled.div`
  margin-top: 40px;
  margin-bottom: 60px;

  h3 {
    font-family: Montserrat;
    font-size: 20px;
    font-weight: 900;
    font-style: normal;
    font-stretch: normal;
    line-height: normal;
    letter-spacing: normal;
    text-align: center;
    color: #4a4a4a;
    text-transform: uppercase;

    img {
      display: block;
      margin: auto;
      margin-bottom: 10px;
      max-height: 30px;
      max-width: 30px;
    }
  }
`

const AllTasks = styled.a`
  font-family: Montserrat;
  font-size: 14px;
  font-weight: 900;
  font-style: normal;
  font-stretch: normal;
  line-height: normal;
  letter-spacing: normal;
  text-transform: uppercase;
  text-decoration: none;
  color: #0089f4;
  display: block;
  text-align: right;
  margin-top: 20px;
  margin-bottom: 10px;

  &:hover {
    text-decoration: underline;
  }
`

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
      interested         : props.interested,
      specialtyInterested: [ ...props.specialtyInterested ]
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

    let pie = d3.layout.pie()
      .value((d) => { return d.value })
      .padAngle(0.02)

    let arc = d3.svg.arc()
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

  addInterest(projectId, specialtyId = null) {
    const { specialtyInterested } = this.state
    new InterestsController().follow(projectId, specialtyId).then(response => {
      if (response.status === 200) {
        if (specialtyId) {
          const newSpecialtyInterested = [...specialtyInterested]
          newSpecialtyInterested[specialtyId - 1] = true
          this.setState({ specialtyInterested: [...newSpecialtyInterested], interested: true })
        } else {
          this.setState({ interested: true })
        }
      } else if (response.status === 401) {
        window.location = '/accounts/new'
      } else {
        throw Error(response.text())
      }
    })
  }

  removeInterest(projectId) {
    const { specialtyInterested } = this.state
    new InterestsController().unfollow(projectId).then(response => {
      if (response.status === 200) {
        let newSpecialtyInterested = [...specialtyInterested].map(_ => false)
        this.setState({ specialtyInterested: [...newSpecialtyInterested], interested: false })
      } else if (response.status === 401) {
        window.location = '/accounts/new'
      } else {
        throw Error(response.text())
      }
    })
  }

  render() {
    const { projectData, tokenData } = this.props
    const { interested, specialtyInterested } = this.state
    const skills = {
      development: 'Software Development',
      design     : 'UX / UI DESIGN',
      research   : 'Research',
      community  : 'COMMUNITY MANAGEMENT',
      data       : 'DATA GATHERING',
      audio      : 'AUDIO & VIDEO PRODUCTION',
      writing    : 'WRITING',
      marketing  : 'MARKETING & SOCIAL MEDIA'
    }
    const skillIds = [5, 6, 8, 2, 3, 1, 7, 4]

    return <div className='project-container animated fadeIn faster'>
      <ProjectSetupHeader
        projectForHeader={this.props.projectForHeader}
        missionForHeader={this.props.missionForHeader}
        owner={this.props.editable}
        current='overview'
        expanded
      />

      <div className='project-award'>
        {!interested &&
          <button
            className='button project-interest__button'
            onClick={() => this.addInterest(projectData.id)}
          >
            Follow
          </button>
        }
        {interested &&
          <button
            className='button project-interest__button'
            onClick={() => this.removeInterest(projectData.id)}
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
      {this.props.tasksBySpecialty.length > 0 &&
        <Tasks>
          <TasksTitle>
            <h2>Tasks</h2>
            <p>Find a task that’s right for your talents, review the details, and get to work!</p>
          </TasksTitle>

          {this.props.tasksBySpecialty.map(specialty =>
            <TasksSpecialty key={specialty[0]}>
              <h3>
                {/* <img src={require(`src/images/specialties/${specialty[0]}.svg`)} /> */}

                {specialty[0]}
              </h3>

              {specialty[1].map(task =>
                <MyTask
                  key={task.id}
                  task={task}
                  displayParents={false}
                />
              )}
            </TasksSpecialty>
          )}

          <AllTasks href={this.props.myTasksPath}>see all available tasks</AllTasks>
        </Tasks>
      }

      {this.props.tasksBySpecialty.length === 0 &&
        <div className='project-skills'>
          <div className='project-skills__title'>SKILLS NEEDED</div>
          <div className='project-skills__subtitle'>Which of your skills are you interesed in contributing?</div>

          {Object.keys(skills).map((skill, index) =>
            <div key={skill} className='project-skill-container'>
              <div className='project-skill__background'>
                <img className='project-skill__background__img' src={require(`src/images/project/${skill}.jpg`)} />
                <div className='project-skill__background__title'>
                  {skills[skill]}
                  <div className='project-skill__background__icon'>
                    <img className='skill-icon--background' src={require(`src/images/project/background.svg`)} />
                    <img className='skill-icon' src={require(`src/images/project/${skill}.svg`)} />
                  </div>
                </div>
              </div>
              <div className='project-skill__interest'>
                {!specialtyInterested[skillIds[index] - 1] &&
                  <div
                    className='project-skill__interest__button'
                    onClick={() => this.addInterest(projectData.id, skillIds[index])}
                  >
                    I'm Interested
                  </div>
                }

                {specialtyInterested[skillIds[index] - 1] &&
                  <div
                    className='project-skill__interest__button'
                    onClick={() => this.removeInterest(projectData.id)}
                  >
                    Following
                  </div>
                }
              </div>
            </div>
          )}
        </div>
      }

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

      <div className='project-interest'>
        <p className='project-interest__text'>Let the project leaders know that you are interested in the project so they can invite you to tasks that you are qualified for.</p>
        {!interested &&
          <button
            className='button project-interest__button'
            onClick={() => this.addInterest(projectData.id)}
          >
            Follow
          </button>
        }
        {interested &&
          <button
            className='button project-interest__button'
            onClick={() => this.removeInterest(projectData.id)}
          >
            Unfollow
          </button>
        }
      </div>
    </div>
  }
}

Project.propTypes = {
  tasksBySpecialty: PropTypes.array,
  projectData     : PropTypes.shape({}),
  tokenData       : PropTypes.shape({}),
  interested      : PropTypes.bool,
  csrfToken       : PropTypes.string,
  editable        : PropTypes.bool,
  myTasksPath     : PropTypes.string,
  editPath        : PropTypes.string,
  missionForHeader: PropTypes.object,
  projectForHeader: PropTypes.object
}

Project.defaultProps = {
  tasksBySpecialty: [ [ null, [] ] ],
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
  interested         : false,
  specialtyInterested: [],
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
