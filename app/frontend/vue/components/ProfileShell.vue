<template>
  <section class="profile-shell">
    <div class="p-4">
      <p class="text-uppercase text-primary fw-semibold small mb-1">{{ heading }}</p>
      <h2 class="h4 fw-bold mb-2">{{ subheading }}</h2>
      <p class="text-muted mb-4">
        Authenticate with Google to view your Stat Machine profile details pulled from the secure API.
      </p>

      <div v-if="loading" class="text-center py-5">
        <div class="spinner-border text-primary mb-3" role="status" />
        <p class="text-muted mb-0">Connecting to Firebase…</p>
      </div>

      <template v-else>
        <div v-if="!firebaseUser" class="auth-card p-4 rounded-4">
          <p class="mb-3 text-white-50 small text-uppercase">Step 1</p>
          <h3 class="h5 text-white">Sign in to unlock predictions synced to your tickets.</h3>
          <button class="btn btn-light btn-lg mt-3" type="button" @click="signIn" :disabled="authenticating">
            <span v-if="!authenticating">Sign in with Google</span>
            <span v-else>
              <span class="spinner-border spinner-border-sm me-2" role="status" />
              Opening provider…
            </span>
          </button>
        </div>

        <div v-else class="profile-card mb-3">
          <div class="d-flex align-items-center gap-3 flex-wrap">
            <div class="profile-avatar profile-avatar--fallback" aria-hidden="true">
              {{ avatarInitials }}
            </div>
            <div>
              <p class="text-uppercase small text-muted mb-1">Welcome back</p>
              <h3 class="h4 mb-0">{{ profileName }}</h3>
              <p class="text-muted mb-0">{{ profileEmail }}</p>
            </div>
            <span class="badge bg-success-subtle text-success ms-auto px-3 py-2">Verified</span>
          </div>

          <div class="d-flex flex-wrap gap-3 mt-4 profile-meta">
            <button type="button" class="btn btn-danger" @click="signOutUser" :disabled="authenticating">
              Sign out
            </button>
          </div>
        </div>
      </template>

      <p v-if="errorMessage" class="text-danger mt-3">{{ errorMessage }}</p>
    </div>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { GoogleAuthProvider, onAuthStateChanged, signInWithPopup, signOut } from 'firebase/auth'
import { auth } from '../../entrypoints/firebase_config'

const props = defineProps({
  profileEndpoint: {
    type: String,
    default: '/api/v1/profile',
  },
  copy: {
    type: Object,
    default: () => ({}),
  },
})

const firebaseUser = ref(null)
const profile = ref(null)
const loading = ref(true)
const errorMessage = ref('')
const fetchingProfile = ref(false)
const authenticating = ref(false)
let unsubscribe = null
const provider = new GoogleAuthProvider()

const heading = computed(() => props.copy?.heading || 'Profile access')
const subheading = computed(() => props.copy?.subheading || 'Securely manage your account')

const profileName = computed(() => profile.value?.name || firebaseUser.value?.displayName || 'Anonymous')
const profileEmail = computed(() => profile.value?.email || firebaseUser.value?.email || 'No email on record')
const profileUid = computed(() => profile.value?.uid || firebaseUser.value?.uid || 'N/A')
const hasAvatar = computed(() => Boolean(profile.value?.picture || firebaseUser.value?.photoURL))
const profileAvatar = computed(() => profile.value?.picture || firebaseUser.value?.photoURL || '')
const avatarInitials = computed(() => {
  const source = profileName.value
  const parts = source.split(/\s+/).filter(Boolean)
  const initials = parts.slice(0, 2).map((word) => word[0]?.toUpperCase() || '').join('')
  return initials || 'SM'
})
const lastAuthenticated = computed(() => {
  if (!profile.value?.authenticated_at) return '—'
  const date = new Date(profile.value.authenticated_at)
  if (Number.isNaN(date.valueOf())) return profile.value.authenticated_at
  return date.toLocaleString()
})

const fetchProfile = async (user) => {
  if (!props.profileEndpoint || !user) return
  fetchingProfile.value = true
  errorMessage.value = ''
  try {
    const token = await user.getIdToken()
    const response = await fetch(props.profileEndpoint, {
      headers: { Authorization: `Bearer ${token}` },
    })

    if (!response.ok) {
      throw new Error('Unable to load profile from API')
    }

    profile.value = await response.json()
  } catch (error) {
    errorMessage.value = error.message || 'Unexpected error loading profile'
  } finally {
    fetchingProfile.value = false
  }
}

const refreshProfile = () => fetchProfile(firebaseUser.value)

const signIn = async () => {
  authenticating.value = true
  errorMessage.value = ''
  try {
    await signInWithPopup(auth, provider)
  } catch (error) {
    errorMessage.value = error.message || 'Sign in failed'
  } finally {
    authenticating.value = false
  }
}

const signOutUser = async () => {
  authenticating.value = true
  errorMessage.value = ''
  try {
    await signOut(auth)
    profile.value = null
  } catch (error) {
    errorMessage.value = error.message || 'Sign out failed'
  } finally {
    authenticating.value = false
  }
}

onMounted(() => {
  unsubscribe = onAuthStateChanged(auth, (user) => {
    firebaseUser.value = user
    profile.value = null
    if (user) {
      fetchProfile(user)
    }
    loading.value = false
  })
})

onBeforeUnmount(() => {
  if (unsubscribe) unsubscribe()
})
</script>

<style scoped>
.profile-shell {
  border-radius: 1.5rem;
  overflow: hidden;
}

.auth-card {
  background: linear-gradient(135deg, #312e81, #1d4ed8);
  color: #fff;
}

.profile-card {
  padding: 1.5rem;
  border: 1px solid rgba(15, 23, 42, 0.08);
  border-radius: 1.25rem;
  background-color: #f8fafc;
  margin-bottom: 1.5rem;
}

.profile-avatar {
  width: 72px;
  height: 72px;
  border-radius: 999px;
  object-fit: cover;
  border: 3px solid #fff;
  box-shadow: 0 10px 20px rgba(15, 23, 42, 0.2);
}

.profile-avatar--fallback {
  background: linear-gradient(135deg, #4338ca, #0ea5e9);
  color: #fff;
  font-weight: 700;
  font-size: 1.4rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.profile-meta {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 1rem;
  margin: 1.5rem 0;
}

.profile-meta dt {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: #94a3b8;
  margin-bottom: 0.15rem;
}

.profile-meta dd {
  margin: 0;
  font-weight: 600;
  color: #0f172a;
}

.bg-success-subtle {
  background-color: rgba(34, 197, 94, 0.12) !important;
}
</style>
