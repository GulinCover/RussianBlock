import Vue from 'vue'
import App from './App.vue'
import Router from 'vue-router'
import Vuex from 'vuex'

Vue.config.productionTip = false

Vue.use(Router)
Vue.use(Vuex)

export const constantRoutes = [
  {
    path: '/fight',
    component: () => import('./components/Fight'),
    hidden: true
  }
]

let router = new Router({
  mode: 'history', // ȥ��url�е�#
  base: process.env.VUE_APP_WEB_PATH,
  scrollBehavior: () => ({y: 0}),
  routes: constantRoutes
})

const store = new Vuex.Store({
  state: {
    coordsTemplate: [
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,0,0,0,0],
    ],

    userId: null,
    shapeList: [
      {
        id: 1,
        shape: {
          1: [[0,1,1],[1,0,1],[1,1,1],[1,2,1]],
          2: [[0,1,1],[1,1,1],[1,2,1],[2,1,1]],
          3: [[0,0,1],[0,1,1],[0,2,1],[1,1,1]],
          4: [[0,1,1],[1,0,1],[1,1,1],[2,1,1]],
        }
      },
      {
        id: 2,
        shape: {
          1: [[0,0,2],[1,0,2],[1,1,2],[1,2,2]],
          2: [[0,0,2],[0,1,2],[1,0,2],[2,0,2]],
          3: [[0,0,2],[0,1,2],[0,2,2],[1,2,2]],
          4: [[0,1,2],[1,1,2],[2,0,2],[2,1,2]],
        }
      },
      {
        id: 3,
        shape: {
          1: [[0,0,3],[0,1,3],[1,0,3],[1,1,3]],
        }
      },
      {
        id: 4,
        shape: {
          1: [[0,0,4],[1,0,4],[1,1,4],[2,1,4]],
          2: [[0,1,4],[0,2,4],[1,0,4],[1,1,4]],
        }
      },
      {
        id: 5,
        shape: {
          1: [[0,2,5],[1,0,5],[1,1,5],[1,2,5]],
          2: [[0,0,5],[1,0,5],[2,0,5],[2,1,5]],
          3: [[0,0,5],[0,1,5],[0,2,5],[1,0,5]],
          4: [[0,0,5],[0,1,5],[1,1,5],[2,1,5]],
        }
      },
      {
        id: 6,
        shape: {
          1: [[0,0,6],[0,1,6],[0,2,6],[0,3,6]],
          2: [[0,0,6],[1,0,6],[2,0,6],[3,0,6]],
        }
      },
      {
        id: 7,
        shape: {
          1: [[0,0,7],[0,1,7],[1,1,7],[1,2,7]],
          2: [[0,1,7],[1,0,7],[1,1,7],[2,0,7]],
        }
      },
    ],
    resourceList: {
      0: '0.PNG',
      1: '1.PNG',
      2: '2.PNG',
      3: '3.PNG',
      4: '4.PNG',
      5: '5.PNG',
      6: '6.PNG',
      7: '7.PNG',
    },
  }
})

new Vue({
  render: h => h(App),
  router,
  store
}).$mount('#app')
