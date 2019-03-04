import React from 'react'
import PropTypes from 'prop-types'
import Layout from './layouts/Layout'
import SidebarItem from './styleguide/SidebarItem'
import SidebarItemBold from './styleguide/SidebarItemBold'
import Icon from './styleguide/Icon'

class BatchIndex extends React.Component {
  constructor(props) {
    super(props)
    this.handleListClick = this.handleListClick.bind(this)
    this.state = {
      selectedBatch: null
    }
  }

  handleListClick(batch) {
    this.setState({
      selectedBatch: batch
    })
  }

  render() {
    return (
      <React.Fragment>
        <Layout
          className="batch-index"
          navTitle={[
            {
              name: 'project settings',
              url : this.props.projectEditPath
            },
            {
              name: 'batches',
              current: true
            }
          ]}
          sidebar={
            <React.Fragment>
              <div className="batch-index--sidebar">
                <SidebarItemBold
                  className="batch-index--sidebar--item__bold"
                  iconLeftName="BATCH/WHITE.svg"
                  iconRightName="PLUS.svg"
                  text="Create a New Batch"
                  onClick={(_) => window.location = `${window.location}/new`}
                />

                { this.props.batches.length > 0 &&
                  <React.Fragment>
                    <hr />

                    <div className="batch-index--sidebar--info">
                      Please select batch:
                    </div>

                    {this.props.batches.map((b, i) =>
                      <SidebarItem
                        className="batch-index--sidebar--item"
                        key={i}
                        iconLeftName="BATCH/WHITE.svg"
                        text={b.name}
                        selected={this.state.selectedBatch === b}
                        onClick={(_) => this.handleListClick(b)}
                      />
                    )}
                  </React.Fragment>
                }
              </div>
            </React.Fragment>
          }
        >
          {this.state.selectedBatch &&
            <div className="batch-index--view">
              <div className="batch-index--view--name">
                {this.state.selectedBatch.name}
              </div>

              <div className="batch-index--view--specialty">
                {this.state.selectedBatch.specialty}
              </div>

              <div className="batch-index--view--team-members" />
              
              <div className="batch-index--view--edit">
                <a href={this.state.selectedBatch.editPath}>
                  <Icon name="iconEdit.svg"/>
                </a>
              </div>

              <div className="batch-index--view--delete">
                <a rel="nofollow" data-method="delete" href={this.state.selectedBatch.destroyPath}>
                  <Icon name="iconTrash.svg"/>
                </a>
              </div>
            </div>
          }
        </Layout>
      </React.Fragment>
    )
  }
}

BatchIndex.propTypes = {
  batches  : PropTypes.array.isRequired,
  projectId: PropTypes.number
}
BatchIndex.defaultProps = {
  batches  : [],
  projectId: null
}

export default BatchIndex
