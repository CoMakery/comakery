import React from 'react'
import { shallow } from 'enzyme'
import Header from 'components/layouts/Header'

describe('Header', () => {
  it('renders correctly without props', () => {
    const wrapper = shallow(<Header isLoggedIn currentPath="/projects/mine" />)

    expect(wrapper).toMatchSnapshot()
    expect(wrapper.exists('.header')).toBe(true)
    expect(wrapper.exists('.header--logo')).toBe(true)
    expect(wrapper.exists('.header--nav')).toBe(true)
    expect(wrapper.exists('.header--nav--links')).toBe(true)
    expect(wrapper.find('.header--nav--links').text()).not.toMatch(/Missions Admin/)
    expect(wrapper.find('.header--nav--links').text()).not.toMatch(/Tokens Admin/)
  })

  it('renders correctly with signup path and without loggedIn flag', () => {
    const wrapper = shallow(<Header currentPath="/accounts/new" />)

    expect(wrapper.find('.header--nav--links--current').text()).toBe('Sign Up')
    expect(wrapper.find('.header--nav--links--current').props().href).toBe('/accounts/new')
  })

  it('renders correctly with signin path and without loggedIn flag', () => {
    const wrapper = shallow(<Header currentPath="/session/new" />)

    expect(wrapper.find('.header--nav--links--current').text()).toBe('Sign In')
    expect(wrapper.find('.header--nav--links--current').props().href).toBe('/session/new')
  })

  it('renders correctly with root path and loggedIn flag', () => {
    const wrapper = shallow(<Header isLoggedIn currentPath="/projects/mine" />)

    expect(wrapper.find('.header--nav--links--current').props().href).toBe('/projects/mine')
  })

  it('renders correctly with My Account path and loggedIn flag', () => {
    const wrapper = shallow(<Header isLoggedIn currentPath="/account" />)

    expect(wrapper.find('.header--nav--links--current').text()).toBe('My Account')
    expect(wrapper.find('.header--nav--links--current').props().href).toBe('/account')
  })

  it('renders correctly with My Projects path and loggedIn flag', () => {
    const wrapper = shallow(<Header isLoggedIn currentPath="/projects/mine" />)

    expect(wrapper.find('.header--nav--links--current').text()).toBe('My Projects')
    expect(wrapper.find('.header--nav--links--current').props().href).toBe('/projects/mine')
  })

  it('renders correctly with admin flag', () => {
    const wrapper = shallow(<Header isLoggedIn isAdmin />)

    expect(wrapper.find('.header--nav--links').text()).toMatch(/Missions Admin/)
    expect(wrapper.find('.header--nav--links').text()).toMatch(/Tokens Admin/)
  })

  it('renders correctly with custom className', () => {
    const wrapper = shallow(<Header className="__test" />)

    expect(wrapper.exists('.header.__test')).toBe(true)
  })
})
