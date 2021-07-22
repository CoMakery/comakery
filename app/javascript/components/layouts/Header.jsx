import React from 'react'
import classNames from 'classnames'
import PropTypes from 'prop-types'
import Icon from './../styleguide/Icon'

const navContent = (isLoggedIn, isAdmin, isWhitelabel, projectAwardsVisible, currentPath) => {
  return <React.Fragment>
    { !isLoggedIn &&
      <div className="header--nav--links">
        { !isWhitelabel &&
          <a href="/projects" className={(currentPath === '/projects') ? 'header--nav--links--current' : null}>
            Projects
          </a>
        }

        { !isWhitelabel &&
          <a href="https://forum.comakery.com" target="_blank">
            Forum
          </a>
        }

        { !isWhitelabel &&
          <a href="https://ledger.comakery.com" target="_blank">
            Blog
          </a>
        }

        { !isWhitelabel &&
          <a target="_blank" href="https://info.comakery.com/pricing/">
            Pricing
          </a>
        }

        { !isWhitelabel &&
          <a target="_blank" href="https://info.comakery.com/about_us/">
            About Us
          </a>
        }

        <a href="/session/new" className={currentPath.match(/session\/new/) ? 'header--nav--links--current header--nav--links--sign' : null} >
          Sign In
        </a>

        <a href="/accounts/new" className={currentPath.match(/accounts\/new/) ? 'header--nav--links--current header--nav--links--sign' : null} >
          Sign Up
        </a>
      </div>
    }

    { isLoggedIn &&
      <div className="header--nav--links">
        { isAdmin &&
          <React.Fragment>
            <a href="/accounts" className={currentPath.match(/^\/accounts$/) ? 'header--nav--links--current' : null}>
              All Accounts
            </a>
            <a href="/missions" className={currentPath.match(/missions/) ? 'header--nav--links--current' : null}>
              Missions Admin
            </a>

            <a href="/tokens" className={currentPath.match(/tokens/) ? 'header--nav--links--current' : null}>
              Tokens Admin
            </a>
          </React.Fragment>
        }

        <a href="/projects/mine" className={currentPath.match(/(?!.*tasks.*)projects.*/) ? 'header--nav--links--current' : null} >
          My Projects
        </a>

        { (!isWhitelabel || projectAwardsVisible) &&
          <a href="/tasks" className={currentPath.match(/\/tasks/) ? 'header--nav--links--current' : null}>
            My Tasks
          </a>
        }

        { !isWhitelabel &&
          <a href="https://forum.comakery.com" target="_blank">
            Forum
          </a>
        }

        { !isWhitelabel &&
          <a href="https://ledger.comakery.com" target="_blank">
            Blog
          </a>
        }

        <a href="/wallets" className={currentPath.match(/\/(wallets)/) ? 'header--nav--links--current' : null} >
          Wallets
        </a>

        <a href="/account" className={currentPath.match(/\/(account$)/) ? 'header--nav--links--current' : null} >
          My Account
        </a>

        <a rel="nofollow" href="/session" data-method="delete" data-turbo="false">
          Sign out
        </a>
      </div>
    }
  </React.Fragment>
}

class Header extends React.Component {
  constructor(props) {
    super(props)
    this.state = { mobileMenuActive: false }
  }
  render() {
    const {className, isAdmin, isLoggedIn, isWhitelabel, whitelabelLogo, projectAwardsVisible, currentPath, ...other} = this.props

    const classnames = classNames(
      'header',
      className
    )

    const {mobileMenuActive} = this.state
    const nav = navContent(isLoggedIn, isAdmin, isWhitelabel, projectAwardsVisible, currentPath)

    return (
      <React.Fragment>
        <div className={classnames} {...other}>
          <div className="header--logo">
            <a href="/">
              { !isWhitelabel &&
                <Icon name="Logo-Header.svg" width="200px" />
              }

              { isWhitelabel &&
                <img src={whitelabelLogo} width="200px" />
              }
            </a>
          </div>

          <div className="header--nav">
            {nav}
          </div>
        </div>

        <div className="header-mobile">
          { !isWhitelabel &&
            <Icon name="Logo-Header.svg" width="162px" />
          }

          { isWhitelabel &&
            <img src={whitelabelLogo} width="162px" />
          }

          <div className="header-mobile__menu-icon" onClick={() => {
            this.setState({mobileMenuActive: !mobileMenuActive})
            document.body.classList.toggle('body--overflow')
          }} >
            <span className={mobileMenuActive ? 'active' : ''} />
          </div>

          { mobileMenuActive &&
            <div className="header-mobile__menu">
              {nav}
            </div>
          }
        </div>
      </React.Fragment>
    )
  }
}
Header.propTypes = {
  currentPath         : PropTypes.string,
  isAdmin             : PropTypes.bool,
  isLoggedIn          : PropTypes.bool,
  projectAwardsVisible: PropTypes.bool,
}
Header.defaultProps = {
  currentPath         : '/',
  isAdmin             : false,
  isLoggedIn          : false,
  projectAwardsVisible: false,
}
export default Header
