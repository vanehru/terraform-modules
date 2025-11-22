import Vue from 'vue'
import VueRouter from 'vue-router'
import AIView from '../views/AIView.vue'
import SignupView from '../views/SignupView.vue'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'home',
        component: () => import(/* webpackChunkName: "about" */ '../views/IndexView.vue')

  },
  {
    path: '/aiview',
    name: '/aiview',
    // route level code-splitting
    // this generates a separate chunk (about.[hash].js) for this route
    // which is lazy-loaded when the route is visited.
        component: AIView

  },
  {
    path: '/signupview',
    name: '/signupview',
    // route level code-splitting
    // this generates a separate chunk (about.[hash].js) for this route
    // which is lazy-loaded when the route is visited.
        component: SignupView

  },
    {
    path: '/dataview',
    name: 'dataview',
        component: () => import(/* webpackChunkName: "about" */ '../views/DataView.vue')

  },
    {
    path: '/loginview',
    name: 'loginview',
        component: () => import(/* webpackChunkName: "about" */ '../views/LoginView.vue')

  },

]

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes
})

export default router
