import ComakerySecurityTokenController from './comakery-security-token_controller'

export default class extends ComakerySecurityTokenController {
  static targets = [ 'form', 'button', 'inputs', 'outputs', 'addressMaxBalance', 'addressLockupUntil', 'addressGroupId', 'addressFrozen' ]
	
	async save() {
		this.setData()
		await this.setAddressPermissions()
	}
	
	setData() {
		this.data.set('addressGroupId', parseInt(this.addressGroupIdTarget.selectedOptions[0].text.match(/\((\d+)\)$/)[1]))
		this.data.set('addressLockupUntil', (new Date(this.addressLockupUntilTarget.value).getTime() / 1000) || 0)
		this.data.set('addressMaxBalance', parseInt(this.addressMaxBalanceTarget.value))
		this.data.set('addressFrozen', this.addressFrozenTarget.value === 'true' ? true : false)
	}
	
  showForm() {		
    document.querySelectorAll('.transfers-table--edit-icon__pencil').forEach(e => {
      e.classList.add('hidden')
    })
		
    this.outputsTargets.forEach((e) => {
      e.classList.add('hidden')
    })

    this.inputsTargets.forEach((e) => {
      e.classList.remove('hidden')
    })
		
		this.formTarget.classList.add('account-form--active')
  }

  hideForm() {
    document.querySelectorAll('.transfers-table--edit-icon__pencil').forEach(e => {
      e.classList.remove('hidden')
    })
		
    this.inputsTargets.forEach((e) => {
      e.classList.add('hidden')
    })
		
    this.outputsTargets.forEach((e) => {
      e.classList.remove('hidden')
    })
		
		this.formTarget.classList.remove('account-form--active')
  }
	
	_submitTransaction(_) {
		// do nothing
	}
	
  _submitConfirmation(_) {
		this.formTarget.submit()
  }
	
  _submitReceipt(_) {
    // do nothing
  }
	
  _submitError(_) {
    // do nothing
  }
}
