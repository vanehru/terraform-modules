import Vue from 'vue'
import VueRouter from 'vue-router'
import store from '../store'
import AIView from '../views/AIView.vue'
import SignupView from '../views/SignupView.vue'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import(/* webpackChunkName: "about" */ '../views/IndexView.vue'),
    meta: { requiresGuest: true }
  },
  {
    path: '/aiview',
    name: 'aiview',
    component: AIView,
    meta: { requiresAuth: true }
  },
  {
    path: '/signupview',
    name: 'signupview',
    component: SignupView,
    meta: { requiresGuest: true }
  },
  {
    path: '/dataview',
    name: 'dataview',
    component: () => import(/* webpackChunkName: "about" */ '../views/DataView.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/loginview',
    name: 'loginview',
    component: () => import(/* webpackChunkName: "about" */ '../views/LoginView.vue'),
    meta: { requiresGuest: true }
  },
]

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes
})

// Navigation guard
router.beforeEach((to, from, next) => {
  const isAuthenticated = store.state.player.userId !== null && store.state.player.userId !== '';
  
  if (to.matched.some(record => record.meta.requiresAuth)) {
    // Route requires authentication
    if (!isAuthenticated) {
      next({
        path: '/',
        query: { redirect: to.fullPath }
      });
    } else {
      next();
    }
  } else if (to.matched.some(record => record.meta.requiresGuest)) {
    // Route is for guests only (login/signup)
    if (isAuthenticated) {
      next('/aiview');
    } else {
      next();
    }
  } else {
    next();
  }
})

export default router
  routes
})

export default router
