<template>
  <div id="app">
    <router-view/>
  </div>
</template>

<script>

export default {
  name: 'App',
  components: {
  },
  mounted() {
    this.$router.push('fight');
  }
}
</script>

<style>
body {
  margin: 0;
  padding: 0;
  user-select: none;
}
</style>
