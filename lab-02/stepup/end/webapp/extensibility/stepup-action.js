exports.onExecutePostLogin = async (event, api) => {
    
  if (event.request.query.scope.split(" ").includes('read:reports')) {
    api.multifactor.enable("any");
  };
  
};