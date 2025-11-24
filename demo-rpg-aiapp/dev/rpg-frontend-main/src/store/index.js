import Vue from 'vue'
import Vuex from 'vuex'
import items from './modules/items' // 商品管理モジュールをインポート
import player from './modules/player';

Vue.use(Vuex)

export default new Vuex.Store({
  modules: {
    items,
    player
  }
})