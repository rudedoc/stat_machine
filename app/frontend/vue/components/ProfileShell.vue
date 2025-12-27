<template>
  <section class="profile-shell">
    <div class="p-4">
      <p class="text-uppercase text-primary fw-semibold small mb-1">{{ heading }}</p>

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

        <div v-else class="profile-card">
          <div class="d-flex align-items-center gap-3 flex-wrap">
            <template v-if="hasAvatar">
              <img :src="profileAvatar" alt="Profile picture" class="profile-avatar" />
            </template>
            <div v-else class="profile-avatar profile-avatar--fallback" aria-hidden="true">
              {{ avatarInitials }}
            </div>
            <div>
              <p class="text-uppercase small text-muted mb-1">Welcome back</p>
              <h3 class="h4 mb-0">{{ profileName }}</h3>
              <p class="text-muted mb-0">{{ profileEmail }}</p>
            </div>
            <span class="badge bg-success-subtle text-success ms-auto px-3 py-2">Verified</span>
          </div>

          <form class="profile-form" @submit.prevent="submitProfileUpdate">
            <div class="mb-3">
              <label class="form-label fw-semibold">Display name</label>
              <input v-model="form.displayName" type="text" class="form-control" maxlength="120" placeholder="Your name" />
            </div>
            <div class="mb-3">
              <label class="form-label fw-semibold">Photo URL</label>
              <input v-model="form.photoUrl" type="url" class="form-control" placeholder="https://example.com/avatar.jpg" />
              <div class="form-text">Provide a link to your preferred avatar.</div>
            </div>
            <div class="d-flex flex-wrap gap-3 align-items-center">
              <button type="submit" class="btn btn-primary" :disabled="updatingProfile">
                <span v-if="!updatingProfile">Save changes</span>
                <span v-else>
                  <span class="spinner-border spinner-border-sm me-2" role="status" />
                  Saving…
                </span>
              </button>
              <button type="button" class="btn btn-outline-secondary" @click="refreshProfile" :disabled="fetchingProfile">
                <span v-if="!fetchingProfile">Refresh profile</span>
                <span v-else>
                  <span class="spinner-border spinner-border-sm me-2" role="status" />
                  Updating…
                </span>
              </button>
              <button type="button" class="btn btn-danger ms-auto" @click="signOutUser" :disabled="authenticating">
                Sign out
              </button>
            </div>
            <p v-if="successMessage" class="text-success mt-3 mb-0">{{ successMessage }}</p>
            <ul v-if="formErrors.length" class="text-danger mt-3 mb-0 ps-3">
              <li v-for="(error, idx) in formErrors" :key="idx">{{ error }}</li>
            </ul>
          </form>
        </div>
      </template>

      <p v-if="errorMessage" class="text-danger mt-3">{{ errorMessage }}</p>
    </div>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
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
const updatingProfile = ref(false)
const successMessage = ref('')
const formErrors = ref([])
const form = reactive({
  displayName: '',
  photoUrl: '',
})
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

const syncForm = () => {
  form.displayName = profile.value?.name || firebaseUser.value?.displayName || ''
  form.photoUrl = profile.value?.picture || firebaseUser.value?.photoURL || ''
}

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
    successMessage.value = ''
  } catch (error) {
    errorMessage.value = error.message || 'Unexpected error loading profile'
  } finally {
    fetchingProfile.value = false
  }
}

const refreshProfile = () => {
  successMessage.value = ''
  formErrors.value = []
  fetchProfile(firebaseUser.value)
}

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
    successMessage.value = ''
    formErrors.value = []
  } catch (error) {
    errorMessage.value = error.message || 'Sign out failed'
  } finally {
    authenticating.value = false
  }
}

const submitProfileUpdate = async () => {
  if (!firebaseUser.value) return
  updatingProfile.value = true
  formErrors.value = []
  successMessage.value = ''

  try {
    const token = await firebaseUser.value.getIdToken()
    const response = await fetch(props.profileEndpoint, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        profile: {
          display_name: form.displayName,
          photo_url: form.photoUrl,
        },
      }),
    })

    if (!response.ok) {
      const data = await response.json().catch(() => ({}))
      if (data.errors) {
        formErrors.value = data.errors
        return
      }
      throw new Error(data.message || 'Unable to update profile')
    }

    profile.value = await response.json()
    successMessage.value = 'Profile updated successfully'
  } catch (error) {
    if (!formErrors.value.length) {
      formErrors.value = [error.message || 'Unexpected error updating profile']
    }
  } finally {
    updatingProfile.value = false
  }
}

onMounted(() => {
  unsubscribe = onAuthStateChanged(auth, (user) => {
    firebaseUser.value = user
    profile.value = null
    if (user) {
      fetchProfile(user)
    } else {
      syncForm()
    }
    loading.value = false
  })
})

onBeforeUnmount(() => {
  if (unsubscribe) unsubscribe()
})

watch(profile, () => {
  syncForm()
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

.profile-form .form-label {
  color: #0f172a;
}

.profile-form .form-text {
  color: #64748b;
}

.bg-success-subtle {
  background-color: rgba(34, 197, 94, 0.12) !important;
}
</style>
