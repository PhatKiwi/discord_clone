// Import user socket for real-time messaging
import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.ChatSetup = {
  mounted() {
    const channelId = this.el.dataset.channelId
    const socketToken = this.el.dataset.socketToken
    
    if (window.currentChannel) {
      window.currentChannel.leave();
    }

    if (!window.socket) {
      window.socket = new window.Phoenix.Socket("/socket", {
        params: { token: socketToken }
      });
      window.socket.connect();
    }

    window.currentChannel = window.socket.channel(`channel:${channelId}`, {});
    
    const messagesContainer = document.getElementById("messages");
    const messageInput = document.getElementById("message-input");
    const messageForm = document.getElementById("message-form");
    const typingIndicator = document.getElementById("typing-indicator");
    const typingUsers = document.getElementById("typing-users");

    let currentlyTyping = [];

    // Join channel and load existing messages
    window.currentChannel.join()
      .receive("ok", (resp) => {
        console.log("Joined channel successfully", resp);
        
        // Load existing messages
        if (resp.messages) {
          messagesContainer.innerHTML = '';
          resp.messages.forEach(message => {
            addMessage(message);
          });
          scrollToBottom();
        }
      })
      .receive("error", (resp) => {
        console.log("Unable to join channel", resp);
      });

    // Listen for new messages
    window.currentChannel.on("new_message", (message) => {
      addMessage(message);
      scrollToBottom();
    });

    // Listen for typing indicators
    window.currentChannel.on("user_typing", (data) => {
      if (!currentlyTyping.includes(data.username)) {
        currentlyTyping.push(data.username);
        updateTypingIndicator();
      }
      
      // Clear typing indicator after 3 seconds
      setTimeout(() => {
        currentlyTyping = currentlyTyping.filter(user => user !== data.username);
        updateTypingIndicator();
      }, 3000);
    });

    // Handle form submission
    messageForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const content = messageInput.value.trim();
      
      if (content) {
        window.currentChannel.push("new_message", { content: content })
          .receive("ok", () => {
            messageInput.value = "";
          })
          .receive("error", (resp) => {
            console.error("Error sending message:", resp);
            alert("Failed to send message");
          });
      }
    });

    // Handle typing indicator
    let typingTimeout = null;
    messageInput.addEventListener("input", () => {
      clearTimeout(typingTimeout);
      
      window.currentChannel.push("typing", {});
      
      typingTimeout = setTimeout(() => {
        // Stop typing indicator after 1 second of no input
      }, 1000);
    });

    function addMessage(message) {
      const messageEl = document.createElement("div");
      messageEl.className = "flex space-x-3 p-2 hover:bg-gray-50 dark:hover:bg-gray-700 rounded";
      messageEl.innerHTML = `
        <div class="flex-shrink-0">
          <div class="h-8 w-8 rounded-full bg-indigo-600 flex items-center justify-center">
            <span class="text-xs font-medium text-white">
              ${message.user.username.charAt(0).toUpperCase()}
            </span>
          </div>
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-baseline space-x-2">
            <p class="text-sm font-medium text-gray-900 dark:text-white">
              ${message.user.username}
            </p>
            <time class="text-xs text-gray-500 dark:text-gray-400">
              ${new Date(message.inserted_at).toLocaleTimeString()}
            </time>
          </div>
          <p class="text-sm text-gray-700 dark:text-gray-300 mt-1 break-words">
            ${escapeHtml(message.content)}
          </p>
        </div>
      `;
      messagesContainer.appendChild(messageEl);
    }

    function updateTypingIndicator() {
      if (currentlyTyping.length > 0) {
        let text = "";
        if (currentlyTyping.length === 1) {
          text = `${currentlyTyping[0]} is typing...`;
        } else if (currentlyTyping.length === 2) {
          text = `${currentlyTyping[0]} and ${currentlyTyping[1]} are typing...`;
        } else {
          text = `${currentlyTyping.slice(0, -1).join(", ")} and ${currentlyTyping[currentlyTyping.length - 1]} are typing...`;
        }
        typingUsers.textContent = text;
        typingIndicator.style.display = "block";
      } else {
        typingIndicator.style.display = "none";
      }
    }

    function scrollToBottom() {
      const container = document.getElementById("messages-container");
      container.scrollTop = container.scrollHeight;
    }

    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    // Focus message input
    messageInput.focus();
  },
  
  destroyed() {
    if (window.currentChannel) {
      window.currentChannel.leave();
      window.currentChannel = null;
    }
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

