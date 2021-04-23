import React from 'react'
import Layout from './../layouts/Layout'
import Button from './Button'
import ButtonBorder from './ButtonBorder'
import ButtonPrimaryDisabled from './ButtonPrimaryDisabled'
import ButtonPrimaryEnabled from './ButtonPrimaryEnabled'
import InputFieldDescription from './InputFieldDescription'
import InputFieldDescriptionMiddle from './InputFieldDescriptionMiddle'
import InputFieldHalfed from './InputFieldHalfed'
import InputFieldWhiteDark from './InputFieldWhiteDark'
import InputFieldDefined from './InputFieldDefined'
import InputFieldDropdown from './InputFieldDropdown'
import InputFieldDropdownHalfed from './InputFieldDropdownHalfed'
import Checkbox from './Checkbox'
import InputFieldUploadFile from './InputFieldUploadFile'
import Icon from './Icon'
import SidebarItem from './SidebarItem'
import SidebarItemBold from './SidebarItemBold'

class Index extends React.Component {
  constructor(props) {
    super(props)
    this.handleInputChange = this.handleInputChange.bind(this)
    this.handleListClick = this.handleListClick.bind(this)
    this.state = {
      'input[text1]'    : '',
      'input[text2]'    : '',
      'input[text3]'    : '',
      'input[text4]'    : '',
      'input[text5]'    : '',
      'input[text6]'    : '',
      'input[select1]'  : 'loggedIn',
      'input[select2]'  : 'all',
      'input[checkbox1]': true,
      'input[checkbox2]': false,
      selectedItem      : null,
      logoLocalUrl      : null
    }
  }

  handleInputChange(event) {
    this.setState({
      [event.target.name]: event.target.type === 'checkbox' ? event.target.checked : event.target.value
    })
  }

  handleListClick(i) {
    this.setState({
      selectedItem: i
    })
  }

  render() {
    return (
      <React.Fragment>
        <Layout
          className="styleguide-index"
          title="layout with sidebar"
          hasBackButton
          sidebar={
            <div className="styleguide-index--sidebar">
              <SidebarItemBold
                className="styleguide-index--sidebar--item__bold"
                iconRightName="PLUS.svg"
                iconLeftName="MARK-WHITE.svg"
                text="Sidebar Item Bold"
              />

              <hr />

              <div className="styleguide-index--sidebar--info">
                Please select an item:
              </div>

              {[1, 2, 3].map((i) =>
                <SidebarItem
                  className="token-index--sidebar--item"
                  key={i}
                  iconLeftName="iconTokensBtc.svg"
                  iconRightName="REARRANGE.svg"
                  text={`${i}`}
                  selected={this.state.selectedItem === i}
                  onClick={(_) => this.handleListClick(i)}
                />
              )}
            </div>
          }
          subfooter={
            <React.Fragment>
              <ButtonBorder
                value="cancel"
                onClick={null}
              />
              <ButtonBorder
                value="save"
                onClick={null}
              />
              <Button
                value="save & close"
                onClick={null}
              />
            </React.Fragment>
          }
        >
          <Button
            value="Tabler"
            onClick={(_)=> window.open('/dev/styleguide/index.html', '_blank')}
          />
          <InputFieldWhiteDark
            name="input[text1]"
            value={this.state['input[text1]']}
            eventHandler={this.handleInputChange}
            symbolLimit={0}
          />
          <InputFieldWhiteDark
            name="input[text2]"
            value={this.state['input[text2]']}
            eventHandler={this.handleInputChange}
          />
          <InputFieldWhiteDark
            required
            name="input[text3]"
            value={this.state['input[text3]']}
            eventHandler={this.handleInputChange}
          />
          <InputFieldHalfed
            name="input[text4]"
            value={this.state['input[text4]']}
            eventHandler={this.handleInputChange}
          />
          <InputFieldDescription
            name="input[text5]"
            value={this.state['input[text5]']}
            eventHandler={this.handleInputChange}
          />
          <InputFieldDescriptionMiddle
            name="input[text6]"
            value={this.state['input[text6]']}
            eventHandler={this.handleInputChange}
          />
          <InputFieldDefined
            value="Logged in team members"
          />
          <InputFieldDropdown
            title="Project visibility"
            selectEntries={[
              ['All team members', 'all'],
              ['Logged in team members', 'loggedIn']
            ]}
            name="input[select1]"
            value={this.state['input[select1]']}
            eventHandler={this.handleInputChange}
          />
          <InputFieldDropdownHalfed
            selectEntries={[
              ['All team members', 'all'],
              ['Logged in team members', 'loggedIn']
            ]}
            name="input[select2]"
            value={this.state['input[select2]']}
            eventHandler={this.handleInputChange}
          />
          <Checkbox
            name="input[checkbox1]"
            checked={this.state['input[checkbox1]']}
            eventHandler={this.handleInputChange}
          />
          <Checkbox
            name="input[checkbox2]"
            checked={this.state['input[checkbox2]']}
            eventHandler={this.handleInputChange}
            checkboxText="Name of the skill"
          />
          <InputFieldUploadFile title="Upload diagram screenshot" />

          <Icon />
          <Icon width={100} height={100} className="styleguide-index--icon" />
          {[
            'atomsIconsSystemTwitter2.svg',
            'WARNING.svg',
            'iconBatchGray.png',
            'atomsIconsSystemSearch.svg',
            'iconDropDownPurple.svg',
            'atomsIconsSystemHome.svg',
            'iconTokensBtc.svg',
            'iconDropDownCopy.svg',
            'iconTrash.svg',
            'atomsIconsSystemAndroid2.svg',
            'atomsIconsSystemPhone.svg',
            'atomsIconSystemArrow.svg',
            'iconMission.svg',
            'iconThreeDots.svg',
            'iconTask.svg',
            'iconClose.svg',
            'iconBitcoinSmall.svg',
            'Logo-Header.svg',
            'Logo-Footer.svg',
            'iconCloseCopy.svg',
            'atomsIconsSystemApple.svg',
            'atomsIconsSystemHeart.svg',
            'atomsIconsSystemWorld.svg',
            'atomsIconsSystemWindows.svg',
            'atomsIconsLinedArrowRight.svg',
            'iconBatch@3x.png',
            'iconBitcoin.svg',
            'atomsIconsSystemPlay.svg',
            'iconPhase.svg',
            'atomsIconsSystemInstagram2.svg',
            'iconBatchGray@2x.png',
            'iconLocked.svg',
            'iconBack.svg',
            'iconDone.svg',
            'iconDropDown.svg',
            'iconBatchPurple.png',
            'iconBatchGray@3x.png',
            'iconBatchPurple@2x.png',
            'iconBatchPurple@3x.png',
            'iconBatch.png',
            'iconTasks.svg',
            'iconBatch@2x.png',
            'atomsIconsSystemFacebook2.svg',
            'atomsIconsSystemCamera.svg',
            'atomsIconsSystemChat.svg',
            'atomsIconsSystemArrow.svg',
            'atomsIconsSystemFreeShipping.svg',
            'iconEdit.svg',
            'atomsDecorationDot.svg',
            'iconTokensCoins.svg',
            'iconCloseDark.svg',
            'atomsIconsSystemLock.svg',
            'charactersCounterVisible.svg',
            'ALERT.svg',
            'PLUS.svg',
            'REARRANGE.svg',
            'MARK-WHITE.svg'
          ].map(i =>
            <Icon key={i} name={i} className="styleguide-index--icon" />
          )}

          <ButtonBorder className="styleguide-index--button" />
          <ButtonPrimaryDisabled className="styleguide-index--button" />
          <ButtonPrimaryEnabled className="styleguide-index--button" />
        </Layout>
      </React.Fragment>
    )
  }
}

export default Index
