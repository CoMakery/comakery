import React from 'react'
import PropTypes from 'prop-types'
import styled, {css} from 'styled-components'

const Wrapper = styled.div`
  font-size: 16px;
  font-weight: bold;
  color: white;
  cursor: default;
  margin-bottom: 1em;
  background-color: #201662;
  background-image: url(${props => props.backgroundImageUrl});
  background-position-x: 50%;
  background-position-y: center;
  background-repeat: no-repeat;
  background-size: cover;
  min-height: 150px;
  display: flex;
  flex-direction: column;
  text-shadow: 1px 1px 1px #3a3a3a;
  box-shadow: 0 5px 10px 0 rgba(0, 0, 0, 0.1);

  ${props => !props.expanded && css`
    margin-left: -150px;
    margin-right: -150px;
    margin-top: -25px;
    margin-bottom: 25px;
  `}

    @media (max-width: 640px) {
      margin-left: -25px;
      margin-right: -25px;
    }
`

const Navigation = styled.div`
  display: flex;
  flex-flow: row;
  justify-content: space-between;
  margin: 0.7em;

  @media (max-width: 640px) {
    flex-direction: column;
  }
`

const NavLink = styled.a`
  color: white;
  text-decoration: ${props => props.current ? 'underline' : 'none'};
  text-transform: uppercase;
  font-size: 12px;
  line-height: 1.5;
  font-weight: bold;
  font-style: normal;
  font-stretch: normal;
  letter-spacing: normal;
  padding-right: 1em;

  &:hover {
    text-decoration: underline;
    color: inherit;
  }
`

const MissionNav = styled.div`
  a {
    display: flex;
  }
`

const ProjectNav = styled.div`
  flex-wrap: wrap;
  display: flex;
  margin-left: auto;
  justify-content: flex-end;

  @media (max-width: 1024px) {
    flex-direction: column;
    padding-left: 1em;
    margin-left: 0;
  }
`

const ProjectInfo = styled.div`
  align-items: center;
  justify-content: center;
  display: flex;
  flex-grow: 2;
  flex-direction: column;

  img {
    max-height: 150px;
    margin-bottom: -50px;
    margin-top: 25px;
    border-radius: 2px;
    box-shadow: 0 10px 20px 0 rgba(32,22,98,.1);
  }

  h1 {
    font-size: 32px;
    font-style: normal;
    font-stretch: normal;
    letter-spacing: normal;
    text-align: center;
    min-height: 100px;
    display: flex;
    align-items: center;
  }

  h2 {
    font-size: 18px;
    text-transform: capitalize;
    font-style: normal;
    font-stretch: normal;
    letter-spacing: normal;
    text-align: center;
    min-height: 100px;
    display: flex;
    align-items: center;
    margin-top: -50px;
  }
`

class ProjectSetupHeader extends React.Component {
  render() {
    const mission = this.props.missionForHeader
    const project = this.props.projectForHeader
    const owner = this.props.owner
    const current = this.props.current

    return (
      <Wrapper backgroundImageUrl={project && project.imageUrl} expanded={this.props.expanded}>
        <Navigation>
          {mission && !project.whitelabel &&
            <MissionNav>
              <NavLink href={mission.url}>
                ← {mission.name}
              </NavLink>
            </MissionNav>
          }

          {project && project.title &&
            <ProjectNav>
              {!project.whitelabel &&
              <NavLink current={current === 'overview'} href={project.landingUrl}>
                overview
              </NavLink>
              }
              {project.fundingUrl &&
              <NavLink current={false} target={'_blank'} href={project.fundingUrl}>
                Funding
              </NavLink>
              }
              {project.gettingStartedUrl &&
              <NavLink current={false} target={'_blank'} href={project.gettingStartedUrl}>
                Getting Started
              </NavLink>
              }
              {project.documentationUrl &&
              <NavLink current={false} target={'_blank'} href={project.documentationUrl}>
                Documentation
              </NavLink>
              }
              {project.githubUrl &&
              <NavLink current={false} target={'_blank'} href={project.githubUrl}>
                GitHub
              </NavLink>
              }
              {(owner || project.showBatches) && this.props.whitelabel != true &&
              <NavLink current={current === 'batches'} href={project.batchesUrl}>
                tasks
              </NavLink>
              }
              {project.governanceUrl &&
              <NavLink current={false} target={'_blank'} href={project.governanceUrl}>
                Governance
              </NavLink>
              }
              {project.videoConferenceUrl &&
              <NavLink current={false} target={'_blank'} href={project.videoConferenceUrl}>
                Video Conference
              </NavLink>
              }

              {(owner || project.showTransfers) &&
                <NavLink current={current === 'transfers'} href={project.transfersUrl}>
                  transfers
                </NavLink>
              }

              {(owner || project.showTransfers) &&
                <NavLink current={current === 'accounts'} href={project.accountsUrl}>
                  accounts
                </NavLink>
              }

              {(owner || project.showTransfers) && project.supportsTransferRules &&
                <NavLink current={current === 'transfer_rules'} href={project.transferRulesUrl}>
                  transfer rules
                </NavLink>
              }
              {owner &&
              <NavLink current={current === 'accesses'} href={project.accessUrl}>
                access
              </NavLink>
              }
              {owner &&
              <NavLink current={current === 'form'} href={project.settingsUrl}>
                settings
              </NavLink>
              }
            </ProjectNav>
          }
        </Navigation>

        <ProjectInfo>
          <h1>{project && project.title || 'New Project'}</h1>
          {project && project.token &&
          <div style={{display: 'flex'}}>
            <span style={{marginTop: '-40px'}}><img src={project.token.logoUrl}/>&nbsp;</span>
            <span>{project.token.name} ({project.token.symbol}) {project.token.network} {project.token.address}</span>
          </div>
          }
        </ProjectInfo>
      </Wrapper>
    )
  }
}

ProjectSetupHeader.propTypes = {
  missionForHeader: PropTypes.object,
  projectForHeader: PropTypes.object,
  owner           : PropTypes.bool,
  current         : PropTypes.string,
  expanded        : PropTypes.bool
}

ProjectSetupHeader.defaultProps = {
  missionForHeader: {
    name    : '',
    url     : '',
    imageUrl: ''
  },
  projectForHeader: {
    settingsUrl       : '',
    adminsUrl         : '',
    batchesUrl        : '',
    contributorsUrl   : '',
    transfersUrl      : '',
    accountsUrl       : '',
    landingUrl        : '',
    imageUrl          : '',
    title             : '',
    owner             : '',
    showBatches       : true,
    showTransfers     : true,
    present           : true,
    githubUrl         : '',
    documentationUrl  : '',
    gettingStartedUrl : '',
    governanceUrl     : '',
    fundingUrl        : '',
    videoConferenceUrl: ''
  },
  owner   : true,
  current : '',
  expanded: false
}

export default ProjectSetupHeader
