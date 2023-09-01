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
    name: 'Block',
    components: {},
    watch: {
      block: {
        deep: true,
        handler(n){
          let shape = null;
          let shapeList = this.$store.state.shapeList;
          for (let el of shapeList) {
            if (el.id === n[0]) {
              let len = 0;
              for (let k in el.shape) {
                len++;
              }
              shape = el.shape[n[1] % len === 0 ? len : n[1] % len];
            }
          }

          if (!shape) {
            return
          }

          this.coords = JSON.parse(JSON.stringify(this.src));
          for (let xy of shape) {
            this.coords[xy[0]][xy[1]] = xy[2];
          }
          this.$forceUpdate();
        },
        immediate: true
      }
    },
    props: {
      block: {
        type: Array,
        default: ()=>{
          return [];
        }
      },
    },
    data() {
      return {
        resource: {},

        coords: [
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
        ],

        src: [
          [0,0,0,0],
          [0,0,0,0],
          [0,0,0,0],
          [0,0,0,0],
        ],
      }
    },
    mounted() {
      this.resource = this.$store.state.resourceList;

      let shape = null;
      let shapeList = this.$store.state.shapeList;
      for (let el of shapeList) {
        if (el.id === this.block[0]) {
          let len = 0;
          for (let k in el.shape) {
            len++;
          }
          shape = el.shape[this.block[1] % len === 0 ? len : this.block[1] % len];
        }
      }

      if (!shape) {
        return
      }

      this.coords = this.src;
      for (let xy of shape) {
        this.coords[xy[0]][xy[1]] = xy[2];
      }

    },
    methods: {
    }
  }
</script>

<style scoped lang="scss">
  .block-wrapper {
    width: 144px;
    height: 144px;

    .block-row {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr 1fr;

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
