import React from 'react'
import PropTypes from 'prop-types'
import FeaturedMission from './FeaturedMission'
import Slider from 'react-slick'
import 'slick-carousel/slick/slick.css'
import 'slick-carousel/slick/slick-theme.css'

import headerImg from '../src/images/featured/header.png'
import logo from '../src/images/styleguide/icons/Logo-Footer.svg'
import developersImg from '../src/images/featured/developers.png'
import communityManagersImg from '../src/images/featured/community-managers.png'

export default class FeaturedMissions extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      topMissions: props.topMissions
    }
  }

  render() {
    const { topMissions } = this.state
    const { moreMissions } = this.props
    return (
      <div className="featured-missions">
        <div className="featured-missions__header">
          <img className="featured-missions__header__img" src={headerImg} />
          <div className="featured-missions__header__description">
            <img className="featured-missions__header__logo" src={logo} />
            <div className="featured-missions__header__title">
              Find Your Mission. <br />
              Prepare For Liftoff.
            </div>
            <div className="featured-missions__header__subtitle">Accelerating Blockchain Adoption</div>
          </div>
        </div>
        <div className="featured-missions__content">
          <p className="featured-missions__content__title">
            Featured<br />
            <span className="featured-missions__content__title--big">missions</span>
          </p>
          <p className="featured-missions__content__description">CoMakery Hosts Blockchain Missions We Believe In</p>
          {
            topMissions.map((mission, index) =>
              <FeaturedMission
                key={mission.id}
                float={index % 2 === 0 ? 'left' : 'right'}
                name={mission.name}
                symbol={mission.symbol}
                imageUrl={mission.imageUrl}
                description={mission.description}
                projects={mission.projects}
                csrfToken={this.props.csrfToken}
              />
            )
          }
        </div>
        <div className="featured-missions__more">
          <p className="featured-missions__more__title">
            40+<br />
            <span className="featured-missions__more__title--big">missions</span>
          </p>
          <p className="featured-missions__more__description">Discover Missions With Cutting Edge Projects</p>
          <Slider className="featured-missions__gallery" slidesToShow={4} slidesToScroll={1}>
            { moreMissions.map((mission, index) =>
              <div>
                <div className="gallery-content">
                  <div className="gallery-content__image">
                    <img src={mission.imageUrl} />
                  </div>
                  <div className="gallery-content__title">{mission.name}</div>
                  <div className="gallery-content__description">{mission.projectsCount}</div>
                </div>
              </div>
            )}
          </Slider>
        </div>
        <div className="featured-missions__footer">
          <div className="featured-missions__footer__stat">
            <div className="featured-missions__footer__stat__num">1000+</div>
            <div className="featured-missions__footer__stat__name">Contributors</div>
          </div>
          <img src={communityManagersImg} />
          <div className="featured-missions__footer__stat">
            <div className="featured-missions__footer__stat__num">500+</div>
            <div className="featured-missions__footer__stat__name">PROJECTS</div>
          </div>
          <img src={developersImg} />
          <div className="featured-missions__footer__stat">
            <div className="featured-missions__footer__stat__num">1,000,000+</div>
            <div className="featured-missions__footer__stat__name">TOKENS AWARDED</div>
          </div>
        </div>
      </div>
    )
  }
}

FeaturedMissions.propTypes = {
  topMissions : PropTypes.array,
  moreMissions: PropTypes.array,
  csrfToken   : PropTypes.string
}

FeaturedMissions.defaultProps = {
  topMissions : [],
  moreMissions: [],
  csrfToken   : '00'
}
