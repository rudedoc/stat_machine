import { onAuthStateChanged } from 'firebase/auth'
import { auth } from './firebase_config'

const initHomeAuth = () => {
  const container = document.querySelector('[data-home-auth]')
  if (!container) return

  const goToProfile = () => {
    window.location.href = '/profile'
  }

  const renderLoading = () => {
    container.innerHTML = `
      <div class="home-auth-inner loading">
        <div class="spinner-border spinner-border-sm text-light" role="status"></div>
        <span>Checking your access…</span>
      </div>
    `
  }

  const renderSignedOut = () => {
    container.innerHTML = `
      <div class="home-auth-inner signed-out">
        <div>
          <p class="eyebrow mb-1">Secure access</p>
          <p class="mb-0">Sign in</p>
        </div>
        <button class="btn btn-outline-light btn-sm" data-home-auth-login type="button">Login</button>
      </div>
    `
  }

  const renderSignedIn = (user) => {
    const name = user?.displayName || 'Edge hunter'
    container.innerHTML = `
      <div class="home-auth-inner signed-in">
        <div>
          <p class="eyebrow mb-1">Welcome</p>
          <p class="mb-0">${name}</p>
        </div>
        <a class="btn btn-light btn-sm" href="/profile">Profile</a>
      </div>
    `
  }

  renderLoading()

  container.addEventListener('click', (event) => {
    const target = event.target.closest('[data-home-auth-login]')
    if (target) {
      goToProfile()
    }
  })

  onAuthStateChanged(auth, (user) => {
    if (user) {
      renderSignedIn(user)
    } else {
      renderSignedOut()
    }
  })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initHomeAuth)
} else {
  initHomeAuth()
}
