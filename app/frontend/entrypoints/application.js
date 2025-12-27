import "./auth";
import "./home_auth";
import 'bootstrap/dist/js/bootstrap.bundle.js'

import { createApp } from 'vue'
import App from '../vue/App.vue'

const bootVueApp = () => {
  const root = document.getElementById('vue-app')
  if (!root) return

  const props = root.dataset.props ? JSON.parse(root.dataset.props) : {}
  createApp(App, props).mount(root)
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', bootVueApp)
} else {
  bootVueApp()
}
