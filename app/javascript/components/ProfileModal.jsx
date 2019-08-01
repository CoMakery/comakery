import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const Modal = styled.div`
  display: flex;
  position: absolute;
  box-sizing: border-box;
  z-index: 9;
  left: -108px;
  bottom: 52px;
  width: 250px;
  padding: 12px;
  border-radius: 2px;
  box-shadow: 0 10px 20px 0 rgba(0, 0, 0, 0.2);
  background-color: #ffffff;
  text-align: left;
  font-family: Montserrat, sans-serif;
  font-size: 12px;
  font-weight: normal;
  font-style: normal;
  font-stretch: normal;
  line-height: normal;
  letter-spacing: normal;
  color: #3a3a3a;

  &::after {
    position: absolute;
    display: block;
    content: '';
    z-index: 9;
    left: 50%;
    bottom: -8px;
    transform: translateX(-50%);
    width: 0;
    height: 0;
    border-left: 6px solid transparent;
    border-right: 6px solid transparent;
    border-top: 8px solid #ffffff;
  }
`

const Image = styled.img`
  width: 45px;
  height: 45px;
  margin-right: 6px;
  border-radius: 50%;
`

const Info = styled.div`
`

const Nickname = styled.div`
  color: #8d9599;
`

const Name = styled.div`
  font-weight: bold;
`

const Specialty = styled.div`
`

const Links = styled.div`
  display: flex;
  margin-top: 1em;
`

const Link = styled.a`
  img {
    height: 18px;
    margin-right: 0.5em;
  }
`

class ProfileModal extends React.Component {
  render() {
    let profile = this.props.profile

    return (
      <React.Fragment>
        <Modal>
          <Image src={profile.imageUrl} />
          <Info>
            <Nickname>
              {profile.nickname}
            </Nickname>

            <Name>
              {profile.firstName} {profile.lastName}
            </Name>

            <Specialty>
              {profile.specialty}
            </Specialty>

            <Links>
              {profile.linkedinUrl &&
                <Link target="_blank" href={profile.linkedinUrl}><img src={require(`src/images/social-color-icons/linkedin.svg`)} /></Link>
              }
              {profile.githubUrl &&
                <Link target="_blank" href={profile.githubUrl}><img src={require(`src/images/social-color-icons/github.svg`)} /></Link>
              }
              {profile.behanceUrl &&
                <Link target="_blank" href={profile.behanceUrl}><img src={require(`src/images/social-color-icons/behance.svg`)} /></Link>
              }
              {profile.dribbleUrl &&
                <Link target="_blank" href={profile.dribbleUrl}><img src={require(`src/images/social-color-icons/dribbble.svg`)} /></Link>
              }
            </Links>
          </Info>
        </Modal>
      </React.Fragment>
    )
  }
}

ProfileModal.propTypes = {
  profile: PropTypes.object.isRequired
}
ProfileModal.defaultProps = {
  profile: {}
}
export default ProfileModal
