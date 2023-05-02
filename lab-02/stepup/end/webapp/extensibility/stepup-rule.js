function triggerStepUp(user, context, callback) {

  console.log(context.request.query.scope); 
  
    context.multifactor = {
      provider: 'none'
    };
  
  if(context.request.query.scope.split(" ").includes('read:reports')) {
       context.multifactor = {
      provider: 'any',
      // ensure that we will prompt MFA, even if the end-user has selected to remember the browser.
      allowRememberBrowser: false
    };
  }  

  return callback(null, user, context);
}