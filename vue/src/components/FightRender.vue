<template>
  <div class="app-container">
    <div class="block-wrapper">
      <div class="block-row" v-for="(row, k) in coords" :key="k">
        <div class="block-col" v-for="(id, k2) in row" :key="k2">
          <img :src="resource[id]">
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'FightRender',
    components: {},
    watch: {
      coords: {
        deep: true,
        handler(){},
        immediate: true
      }
    },
    props: {
      coords: {
        type: Array,
        default: ()=>{
          return [];
        }
      },
    },
    data() {
      return {
        resource: {},
      }
    },
    mounted() {
      this.resource = this.$store.state.resourceList;
    },
    methods: {
    }
  }
</script>

<style scoped lang="scss">
  .block-wrapper {
    width: 360px;
    height: 576px;

    .block-row {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr;

      .block-col {
        width: 36px;
        height: 36px;

        > img {
          width: inherit;
          height: inherit;
        }
      }
    }
  }
</style>
