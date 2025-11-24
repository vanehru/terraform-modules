const app = new Vue({
  el: '#app',
  vuetify: new Vuetify(),
  data: {
    ID: '',
    Name: '',
    dataList: [],
    snackbar: false,     
    snackbarMessage: '',   
    dialog: false,       
    dialogMessage: '' 
  },
})