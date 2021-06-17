import { Controller } from 'stimulus';
import Rails from '@rails/ujs';
import PubSub from 'pubsub-js'
import { FLASH_ADD_MESSAGE } from "../../src/javascripts/eventTypes";

export default class extends Controller {
  static targets = ['submit'];

  connect() {
    this.createdEvent = new CustomEvent('invites:created', { bubbles: true });

    this.jmodal = this.element.jModalController;
  }

  onSubmit(event) {
    event.preventDefault();

    Rails.ajax({
      type: this.element.attributes.method.value,
      url: this.element.attributes.action.value,
      data: new FormData(this.element),
      success: (response) => {
        this.element.dispatchEvent(this.createdEvent);
        this._addFlashMessage('notice', response.message)
      },
      error: (response, status) => {
        if (status === 'Unauthorized') {
          this._addFlashMessage('error', 'You are not authorized to perform this action')
        }

        if (response.errors) {
          this._addErrors(response.errors)
        }
      }
    });
  }

  _addErrors(errors) {
    let $errorsContainer = $('#invite-person ul.errors');

    $errorsContainer.html('');

    errors.forEach((error) => {
      $errorsContainer.append($('<li style="list-style-type: none; text-transform: none;"/>').html(error));
      $errorsContainer.addClass('alert');
    })
  }

  _addFlashMessage(severity, text) {
    PubSub.publish(FLASH_ADD_MESSAGE, { severity, text })
  }
}
