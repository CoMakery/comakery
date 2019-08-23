import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'
import Layout from './Layout'
import ProjectSetupHeader from './ProjectSetupHeader'

class ProjectSetup extends React.Component {
  render() {
    const {
      className,
      sidebar,
      projectId,
      projectTitle,
      projectPage,
      subfooter,
      children,
      editable,
      ...other
    } = this.props

    const classnames = classNames(
      'project-setup',
      className
    )

    return (
      <React.Fragment>
        <Layout
          className={classnames}
          customTitle={
            <ProjectSetupHeader
              projectTitle={projectTitle}
              projectId={projectId}
              projectPage={projectPage}
              projectOwner={editable}
            />
          }
          sidebar={sidebar}
          subfooter={subfooter}
          {...other}
        >
          {children}
        </Layout>
      </React.Fragment>
    )
  }
}

ProjectSetup.propTypes = {
  className   : PropTypes.string,
  projectId   : PropTypes.number,
  projectTitle: PropTypes.string,
  projectPage : PropTypes.string,
  subfooter   : PropTypes.object,
  sidebar     : PropTypes.object,
  editable    : PropTypes.bool
}
ProjectSetup.defaultProps = {
  className   : '',
  projectId   : null,
  projectTitle: '',
  projectPage : '',
  subfooter   : null,
  sidebar     : null,
  editable    : true
}
export default ProjectSetup
