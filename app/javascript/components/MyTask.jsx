import React from 'react'
import PropTypes from 'prop-types'
import CurrencyAmount from './CurrencyAmount'
import Userpics from './Userpics'
import styled, { css } from 'styled-components'

const Wrapper = styled.div`
  display: flex;
  flex-direction: column;
  box-shadow: 0 5px 10px 0 rgba(0, 0, 0, 0.1);
  height: 80px;
  padding: 10px 20px;
  margin-bottom: 20px;
  text-transform: uppercase;
  background-color: white;

  @media (max-width: 1024px) {
    height: auto;
  }
`

const RightBorder = styled.div`
  width: 2px;
  height: 100px;
  box-shadow: 0 5px 10px 0 rgba(0, 0, 0, .2);
  background-color: #5037f7;
  z-index: 10;
  position: absolute;
  margin-left: -20px;
  margin-top: -10px;

  ${props => props.status === 'ready' && css`
    background-color: #4a4a4a;
  `}

  ${props => props.status === 'started' && css`
    background-color: #008e9b;
  `}

  ${props => props.status === 'submitted' && css`
    background-color: #007ae7;
  `}

  ${props => props.status === 'accepted' && css`
    background-color: #5037f7;
  `}

  ${props => props.status === 'paid' && css`
    background-color: #fb40e5;
  `}

  ${props => props.status === 'rejected' && css`
    background-color: #ff4d4d;
  `}

  @media (max-width: 1024px) {
    height: 58px;
  }
`

const FirstRow = styled.div`
  margin-bottom: 10px;
  display: flex;
  width: 100%;
  justify-content: space-between;
  align-items: flex-start;

  @media (max-width: 1024px) {
    flex-direction: column;
  }
`

const SecondRow = styled.div`
  min-height: 28px;
  margin-bottom: 10px;
  display: flex;
  width: 100%;
  justify-content: space-between;
  align-items: center;

  @media (max-width: 1024px) {
    flex-direction: column;
  }
`

const ThirdRow = styled.div`
  display: flex;
  width: 100%;

  @media (max-width: 1024px) {
    flex-direction: column;
  }
`

const Name = styled.div`
  font-family: Montserrat;
  font-size: 16px;
  font-weight: bold;
  font-style: normal;
  font-stretch: normal;
  line-height: normal;
  letter-spacing: normal;
  color: #3a3a3a;

  @media (max-width: 1024px) {
    margin-bottom: 15px;
  }
`

const BlockWrapper = styled.div`
  margin-right: auto;
`

const Mission = styled.div`
  font-family: Montserrat;
  font-size: 12px;
  font-weight: 900;
  font-style: normal;
  font-stretch: normal;
  line-height: 1.4;
  letter-spacing: normal;
  color: #4a4a4a;

  a {
    text-decoration: none;
    color: #0089f4;
    font-weight: 600;

    &:hover {
      text-decoration: underline;
    }

    @media (max-width: 1024px) {
      display: block;
    }
  }

  @media (max-width: 1024px) {
    margin-bottom: 15px;
  }
`

const Project = styled.div`
  font-family: Montserrat;
  font-size: 12px;
  font-weight: 900;
  font-style: normal;
  font-stretch: normal;
  line-height: 1.4;
  letter-spacing: normal;
  color: #4a4a4a;

  a {
    text-decoration: none;
    color: #0089f4;
    font-weight: 600;

    &:hover {
      text-decoration: underline;
    }

    @media (max-width: 1024px) {
      display: block;
    }
  }

  @media (max-width: 1024px) {
  margin-bottom: 15px;
  margin-top: 15px;
  }
`

const TaskAction = styled.a`
  ${props => props.componentStyle === 'link' && css`
    font-family: Montserrat;
    font-size: 14px;
    font-weight: bold;
    font-style: normal;
    font-stretch: normal;
    line-height: normal;
    letter-spacing: normal;
    text-align: right;
    color: #8d9599;
    text-transform: uppercase;
    text-decoration: none;

    &:hover {
      text-decoration: underline;
    }

    @media (max-width: 1024px) {
      display: none;
    }
  `}

  ${props => props.componentStyle === 'button' && css`
    display: none;
    text-decoration: none;
    height: 30px;
    padding: 6px 12px;
    margin-right: 15px;
    min-width: 90px;
    color: white;
    background-color: #8d9599;
    box-shadow: 0 5px 10px 0 rgba(32, 22, 98, .1);
    font-family: Montserrat, sans-serif;
    font-size: 14px;
    font-weight: bold;
    text-transform: uppercase;
    outline: none;
    border: none;
    border-radius: 0;
    transition: none;
    cursor: pointer;
    box-sizing: border-box;
    appearance: none;
    align-items: flex-start;
    text-align: center;
    margin-bottom: 15px;
    width: fit-content;

    &:hover {
      text-decoration: underline;
    }

    @media (max-width: 1024px) {
      display: inline-block;
    }
  `}

  ${props => props.actionAvailable && props.componentStyle === 'link' && css`
    color: #0089f4;
  `}

  ${props => props.actionAvailable && props.componentStyle === 'button' && css`
    background-color: #0089f4;
  `}
`

const TaskDetails = styled.a`
  font-family: Montserrat;
  font-size: 10px;
  font-weight: bold;
  font-style: normal;
  font-stretch: normal;
  line-height: normal;
  letter-spacing: normal;
  color: #201662;
  margin-left: auto;
  text-transform: uppercase;
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }

  @media (max-width: 1024px) {
    margin-left: initial;
    margin-top: 15px;
    margin-bottom: 15px;
  }
`

const Status = styled.div`
  font-family: Montserrat;
  font-size: 10px;
  color: #4a4a4a;
  font-weight: 500;
  font-style: normal;
  font-stretch: normal;
  line-height: normal;
  letter-spacing: normal;
  margin-right: 2em;

  b {
    font-weight: 900;
  }
`

const Type = styled.div`
  font-family: Montserrat;
  font-size: 10px;
  font-weight: 500;
  color: #4a4a4a;
  font-style: normal;
  font-stretch: normal;
  line-height: normal;
  letter-spacing: normal;
  margin-right: 2em;

  b {
    font-weight: 900;
  }
`

const Contributor = styled.div`
  font-family: Montserrat;
  font-size: 10px;
  font-weight: 500;
  color: #4a4a4a;
  text-transform: uppercase;
  font-style: normal;
  font-stretch: normal;
  line-height: normal;
  letter-spacing: normal;
  flex-wrap: nowrap;
  display: flex;
  margin-right: 2em;

  b {
    font-weight: 900;
  }

  @media (max-width: 1024px) {
    margin-top: 15px;
  }
`

class TaskActionComponent extends React.Component {
  render() {
    let task = this.props.task
    return (
      <TaskAction
        componentStyle={this.props.componentStyle}
        href={
          ((task.status === 'accepted' && task.issuer.self) && task.paymentUrl) ||
          ((task.status === 'paid') && task.paymentUrl) ||
          ((task.status === 'accepted' && !task.issuer.self && !task.contributor.walletPresent) && '/account') ||
          (task.detailsUrl)
        }
        actionAvailable={
          (task.status === 'ready') ||
          (task.status === 'started') ||
          (task.status === 'submitted' && task.issuer.self) ||
          (task.status === 'accepted' && !task.issuer.self && !task.contributor.walletPresent) ||
          (task.status === 'accepted' && task.issuer.self && task.contributor.walletPresent)
        }
      >
        {task.status === 'ready' &&
          <React.Fragment>Start Task</React.Fragment>
        }
        {task.status === 'started' &&
          <React.Fragment>Submit Task</React.Fragment>
        }
        {task.status === 'submitted' && !task.issuer.self &&
          <React.Fragment>Awaiting Review</React.Fragment>
        }
        {task.status === 'submitted' && task.issuer.self &&
          <React.Fragment>Review Task</React.Fragment>
        }
        {task.status === 'accepted' && !task.issuer.self && task.contributor.walletPresent &&
          <React.Fragment>Awaiting Payment</React.Fragment>
        }
        {task.status === 'accepted' && !task.issuer.self && !task.contributor.walletPresent &&
          <React.Fragment>Provide Wallet</React.Fragment>
        }
        {task.status === 'accepted' && task.issuer.self && task.contributor.walletPresent &&
          <React.Fragment>Pay Contributor</React.Fragment>
        }
        {task.status === 'accepted' && task.issuer.self && !task.contributor.walletPresent &&
          <React.Fragment>Account Pending</React.Fragment>
        }
        {task.status === 'paid' &&
          <React.Fragment>Paid</React.Fragment>
        }
        {task.status === 'rejected' &&
          <React.Fragment>Rejected</React.Fragment>
        }
      </TaskAction>
    )
  }
}

class MyTask extends React.Component {
  render() {
    let task = this.props.task
    return (
      <React.Fragment>
        <Wrapper>
          <RightBorder status={task.status} />
          <FirstRow>
            <Name>{task.name}</Name>
            <CurrencyAmount
              amount={task.totalAmount}
              currency={task.token.currency}
              logoUrl={task.token.logo}
            />
          </FirstRow>

          <SecondRow>
            <BlockWrapper>
              <Project>PROJECT <a href={task.project.url}>{task.project.name}</a></Project>
              {task.mission.name &&
                <Mission>MISSION <a href={task.mission.url}>{task.mission.name}</a></Mission>
              }
            </BlockWrapper>

            {this.props.displayActions &&
              <TaskActionComponent componentStyle="link" task={task} />
            }
          </SecondRow>

          <ThirdRow>
            <Status>
              <b>{task.status} </b>
              {task.updatedAt} ago
            </Status>
            <Type>
              <b>TYPE </b>
              {task.batch.specialty || 'General'}
            </Type>
            {task.contributor.name &&
              <Contributor>
                <Userpics pics={[task.contributor.image]} limit={1} />
                {task.contributor.name}
              </Contributor>
            }

            {this.props.displayActions &&
              <TaskDetails href={task.detailsUrl}>
                View Task Details
              </TaskDetails>
            }

            {this.props.displayActions &&
              <TaskActionComponent componentStyle="button" task={task} />
            }
          </ThirdRow>
        </Wrapper>
      </React.Fragment>
    )
  }
}

MyTask.propTypes = {
  task          : PropTypes.object,
  displayActions: PropTypes.bool
}
MyTask.defaultProps = {
  task: {
    status: null,
    token : {
      currency: 'test',
      logo    : 'test'
    },
    project: {
      name: null,
      url : null
    },
    mission: {
      name: null,
      url : null
    },
    batch: {
      specialty: null
    },
    contributor: {
      name : null,
      image: null
    }
  },
  displayActions: true
}
export default MyTask
