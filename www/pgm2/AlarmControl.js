if (typeof AM_checkVar === 'undefined') {

  var AM_checkVar=1;

  var req = new XMLHttpRequest();
  req.open('GET', document.location, false);
  req.send(null);
  var csrfToken = req.getResponseHeader('X-FHEM-csrfToken');
  
}