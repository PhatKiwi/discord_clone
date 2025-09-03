// Bring in Phoenix channels client library:
import {Socket} from "phoenix"

// Make Phoenix Socket available globally for chat functionality
window.Phoenix = { Socket }

export default Socket
