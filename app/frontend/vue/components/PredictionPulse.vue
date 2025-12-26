<template>
  <section class="prediction-pulse">
    <div class="pulse-header">
      <div>
        <p class="eyebrow mb-1">{{ liveStatus }}</p>
        <h2 class="h5 mb-0">{{ title }}</h2>
      </div>
      <span class="live-chip">live</span>
    </div>

    <p class="pulse-subhead">
      Confidence recalibrates every 60 seconds across synced sportsbooks.
    </p>

    <div v-if="featuredPrediction" class="featured-card">
      <p class="small text-uppercase text-white-50 mb-1">{{ featuredPrediction.league }}</p>
      <div class="d-flex justify-content-between align-items-start gap-3">
        <div>
          <h3 class="h4 mb-1">{{ featuredPrediction.match }}</h3>
          <p class="small text-white-50 mb-2">
            Kickoff {{ formatKickoff(featuredPrediction.kickoff) }}
          </p>
        </div>
        <span class="trend-chip">{{ featuredPrediction.trend }}</span>
      </div>
      <div class="featured-metrics">
        <div>
          <p class="label">Prob. edge</p>
          <h4 class="mb-0">{{ probabilityPercent(featuredPrediction) }}%</h4>
        </div>
        <div>
          <p class="label">Value</p>
          <h4 class="mb-0">{{ featuredPrediction.edge }}</h4>
        </div>
      </div>
      <div class="progress progress-thick mb-2">
        <div
          class="progress-bar bg-gradient"
          role="progressbar"
          :style="{ width: confidenceWidth + '%' }"
          :aria-valuenow="confidenceWidth"
          aria-valuemin="0"
          aria-valuemax="100"
        />
      </div>
      <div class="d-flex justify-content-between text-white-50 small">
        <span>Edge confidence</span>
        <strong class="text-white">{{ confidenceWidth }}%</strong>
      </div>
    </div>

    <ul class="pulse-feed list-unstyled mb-0">
      <li
        v-for="(prediction, idx) in predictionList"
        :key="`${prediction.league}-${prediction.match}-${idx}`"
        class="pulse-feed__item"
        :class="{ 'pulse-feed__item--active': idx === activeIndex }"
        @mouseenter="setActive(idx)"
      >
        <div>
          <p class="small text-uppercase text-white-50 mb-0">{{ prediction.league }}</p>
          <strong class="d-block">{{ prediction.match }}</strong>
          <span class="small text-white-50">{{ formatKickoff(prediction.kickoff) }}</span>
        </div>
        <div class="feed-metrics">
          <span class="badge bg-success bg-opacity-10 text-success fw-semibold">{{ prediction.edge }}</span>
          <span class="badge bg-secondary bg-opacity-25">{{ prediction.confidence }}%</span>
        </div>
      </li>
    </ul>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'

const props = defineProps({
  title: {
    type: String,
    default: 'Live Prediction Pulse',
  },
  predictions: {
    type: Array,
    default: () => [],
  },
})

const predictionList = computed(() => props.predictions ?? [])
const activeIndex = ref(0)
const featuredPrediction = computed(() => predictionList.value[activeIndex.value] || predictionList.value[0] || null)
const confidenceWidth = computed(() => (featuredPrediction.value ? Math.round(Number(featuredPrediction.value.confidence) || 0) : 0))
const liveStatus = computed(() => `${predictionList.value.length} curated plays streaming now`)

let intervalId

const setActive = (idx) => {
  activeIndex.value = idx
}

const startRotation = () => {
  stopRotation()
  if (predictionList.value.length <= 1 || typeof window === 'undefined') return
  intervalId = window.setInterval(() => {
    activeIndex.value = (activeIndex.value + 1) % predictionList.value.length
  }, 5000)
}

const stopRotation = () => {
  if (intervalId) {
    clearInterval(intervalId)
    intervalId = undefined
  }
}

const probabilityPercent = (prediction) => {
  const prob = Number(prediction?.probability)
  if (Number.isNaN(prob)) return '0'
  return Math.round(prob * 100)
}

const formatKickoff = (isoString) => {
  if (!isoString) return 'TBD'
  const date = new Date(isoString)
  if (Number.isNaN(date.valueOf())) return isoString
  return date.toLocaleString(undefined, { hour: '2-digit', minute: '2-digit', weekday: 'short' })
}

onMounted(() => {
  startRotation()
})

onBeforeUnmount(() => {
  stopRotation()
})

watch(
  () => predictionList.value.length,
  () => {
    activeIndex.value = 0
    startRotation()
  }
)
</script>

<style scoped>
.prediction-pulse {
  background: radial-gradient(circle at top, #1f52ff 0%, #0f172a 60%);
  color: #fff;
  border-radius: 1.5rem;
  padding: 2rem;
  box-shadow: 0 25px 40px rgba(15, 23, 42, 0.5);
  min-height: 100%;
}

.pulse-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.eyebrow {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: rgba(255, 255, 255, 0.6);
}

.live-chip {
  text-transform: uppercase;
  font-size: 0.7rem;
  letter-spacing: 0.15em;
  background: rgba(16, 255, 203, 0.15);
  color: #10ffcb;
  border: 1px solid rgba(16, 255, 203, 0.4);
  border-radius: 999px;
  padding: 0.35rem 0.9rem;
}

.pulse-subhead {
  margin-bottom: 1.25rem;
  color: rgba(255, 255, 255, 0.65);
}

.featured-card {
  background: rgba(15, 23, 42, 0.65);
  border: 1px solid rgba(255, 255, 255, 0.08);
  padding: 1.5rem;
  border-radius: 1.25rem;
  margin-bottom: 1.5rem;
}

.featured-metrics {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.featured-metrics h4 {
  font-weight: 700;
}

.featured-metrics .label {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.65);
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.pulse-feed {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.pulse-feed__item {
  background: rgba(15, 23, 42, 0.45);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 1rem;
  padding: 1rem 1.25rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  transition: transform 0.3s ease, border-color 0.3s ease, background 0.3s ease;
}

.pulse-feed__item--active {
  transform: translateX(6px);
  border-color: rgba(16, 255, 203, 0.4);
  background: rgba(16, 255, 203, 0.08);
}

.feed-metrics {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.35rem;
}

.trend-chip {
  font-size: 0.75rem;
  padding: 0.35rem 0.75rem;
  border-radius: 999px;
  background: rgba(16, 255, 203, 0.15);
  color: #10ffcb;
  font-weight: 600;
}

.progress-thick {
  height: 0.6rem;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
}

.bg-gradient {
  background: linear-gradient(90deg, #22d3ee, #3b82f6, #818cf8);
}

@media (max-width: 575px) {
  .prediction-pulse {
    padding: 1.5rem;
  }

  .pulse-feed__item {
    flex-direction: column;
    align-items: flex-start;
  }

  .feed-metrics {
    width: 100%;
    flex-direction: row;
    justify-content: space-between;
  }
}
</style>
