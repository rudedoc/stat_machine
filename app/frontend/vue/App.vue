<template>
  <component :is="resolvedComponent" v-bind="componentProps" />
</template>

<script setup>
import { computed } from 'vue'
import PredictionPulse from './components/PredictionPulse.vue'
import ProfileShell from './components/ProfileShell.vue'

const props = defineProps({
  component: {
    type: String,
    default: 'prediction-pulse',
  },
  title: {
    type: String,
    default: 'Live Prediction Pulse',
  },
  predictions: {
    type: Array,
    default: () => [],
  },
  profileEndpoint: {
    type: String,
    default: '',
  },
  copy: {
    type: Object,
    default: () => ({}),
  },
})

const registry = {
  'prediction-pulse': PredictionPulse,
  'profile-shell': ProfileShell,
}

const resolvedComponent = computed(() => registry[props.component] || PredictionPulse)

const componentProps = computed(() => {
  if (resolvedComponent.value === ProfileShell) {
    return {
      profileEndpoint: props.profileEndpoint,
      copy: props.copy,
    }
  }

  return {
    title: props.title,
    predictions: props.predictions,
  }
})
</script>
