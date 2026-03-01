import consumer from "channels/consumer"

consumer.subscriptions.create("AppointmentChannel", {
  connected() {
    console.log("Connected to AppointmentChannel")
  },

  disconnected() {
    console.log("Disconnected from AppointmentChannel")
  },

  received(data) {
    console.log("Received appointment notification:", data)
    this.showNotification(data)
  },

  showNotification(data) {
    const { action, appointment } = data
    const container = document.getElementById("toast-container")

    if (!container) {
      console.warn("Toast container not found")
      return
    }

    const toast = document.createElement("div")
    toast.className = `toast toast-${action}`

    let message = ""
    switch(action) {
      case "created":
        message = `New appointment: ${appointment.patient_name} with ${appointment.provider_name}`
        break
      case "updated":
        message = `Appointment updated: ${appointment.patient_name} - ${appointment.status}`
        break
      case "destroyed":
        message = `Appointment canceled: ${appointment.patient_name}`
        break
    }

    toast.innerHTML = `
      <div class="toast-header">
        <strong>${action.toUpperCase()}</strong>
        <button type="button" class="toast-close" aria-label="Close">&times;</button>
      </div>
      <div class="toast-body">
        <p>${message}</p>
        <small>${appointment.scheduled_at}</small>
      </div>
    `

    container.appendChild(toast)

    setTimeout(() => {
      toast.classList.add("show")
    }, 100)

    const closeButton = toast.querySelector(".toast-close")
    closeButton.addEventListener("click", () => {
      this.removeToast(toast)
    })

    setTimeout(() => {
      this.removeToast(toast)
    }, 5000)
  },

  removeToast(toast) {
    toast.classList.remove("show")
    setTimeout(() => {
      toast.remove()
    }, 300)
  }
})
