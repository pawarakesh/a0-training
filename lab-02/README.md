# Lab 2: Calling an API

This lab covers the process for adding sign-in to a basic Node.js application and calling an API. This lab is the same exercise we provide for new employees in a technical role here at Auth0.

::: warning
The Node OIDC and bearer token npm packages that this lab uses has not been tested, licensed, or officially released and should not be used in production.
:::

## Prerequisites

- Read [Using Express Middleware](https://expressjs.com/en/guide/using-middleware.html) (optional)
- Read [Beginner's Guide to Using npm](https://nodesource.com/blog/an-absolute-beginners-guide-to-using-npm/) (optional)

## What You'll Need

**Node environment** - Install [Node.js](https://nodejs.org) directly or using [Homebrew](https://formulae.brew.sh/formula/node) or [NVM](https://github.com/nvm-sh/nvm) on a Mac. The labs were tested on Node.js v10.15.0 and NPM 6.4.1 (though they may work in other versions as well).

---

**An Auth0 account** - Sign up for a free Auth0 account [here](https://auth0.com/signup). We recommend starting with a new, empty tenant that can be deleted when you have completed the exercises. If you're using an existing test or dev tenant, make sure that all Rules are turned **off** and MFA is turned **off**.

---

**An Auth0 database user** - Use a new username/email and password user in a test database connection instead of a social, enterprise, or passwordless login. While social logins might work, using development keys can cause the labs to run differently. Choose a simple password that's easy to type as you will be logging in and out multiple times. You can use the same user across all of the labs.

---

**A web browser** - This lab was built and tested using Google Chrome; Safari, Firefox, and Edge should all work fine as well. Disable any active ad blockers used for the domain of your local site, as well as for the Auth0 domain from your tenant.

---

**The Identity Labs Git repo** - All the code you need to start, as well as the completed exercise for guidance, is located [here](https://github.com/auth0/identity-102-exercises). You need to clone that repo just once for all four labs. Use the correct folder relative to the lab you are working on. All file references in this lab are relative to `/begin` unless otherwise indicated. An `/end` folder is included as well to help with troubleshooting and compare your work with a working sample.

---

**For macOS users** - If you are new to macOS, check [these quick tips](https://blogs.mulesoft.com/dev/newbie/quick-tips-for-developers-new-to-mac/) for developers new to Mac. Make sure you allow the display of hidden files and become familiar with running basic commands in the terminal.


---

**For Windows users** - We recommend that you use the Windows PowerShell terminal (instead of the Windows command line) so that the terminal commands provided in the lab instructions work as they are. This is because the syntax of the commands used in the labs is the same for the Mac and PowerShell terminals.


# Lab 2, Exercise 1: Consuming APIs

::: warning
If you came to this page directly, go to the [first page of this lab](/identity-labs/02-calling-an-api) and read through the instructions before getting started.
:::

After learning how to secure your web application with Auth0 in [lab 1](/identity-labs/01-web-sign-in), you will now learn how to make this application consume APIs on behalf of your users. You will start by running an unsecured API and a web application to see both working together, and then you will secure your API with Auth0.


1. Open a new terminal and browse to `/lab-02/begin/api` in your locally-cloned copy of the identity exercise repo. This is where the code for your API resides. The API is an Express backend that contains a single endpoint. This endpoint (served under the root path) returns expenses, which are data that belong to each user (though they are static and the same for all).

<%= include('../_includes/_git-clone-note') %>

2. Install the dependencies using npm:

```bash
# Make sure we're in the right directory
❯ pwd
/Users/username/identity-102-exercises/lab-02/begin/api

❯ npm install
# Ignore any warnings

added XX packages in X.XXs
```

3. Next, copy `.env-sample` to `.env` and start the API:

```bash
❯ cp .env-sample .env
❯ npm start

listening on http://localhost:3001
```

::: note
If you see a message like *Error: listen EADDRINUSE :::3001* in your terminal after starting the application, this means that port 3001 is in use somewhere. Change the `PORT` value in your `.env` file to "3002" and try again.
:::

4. In a new terminal window or tab, navigate to the `/lab-02/begin/webapp` directory and install the dependencies using npm:

```bash
# Navigating from the previous directory
❯ cd ../webapp

# Make sure we're in the right directory
❯ pwd
/Users/username/identity-102-exercises/lab-02/begin/webapp

❯ npm install
# Ignore any warnings

added XX packages in X.XXs
```

5. Once again, copy the `.env-sample` to `.env` for the web application:

```bash
❯ cp .env-sample .env
```

6. Update the web application `.env` file you just created with the same values as you used in lab 1. If you did not do lab 1 first, follow steps 9 through 15 [on this page](/identity-labs/01-web-sign-in/exercise-01) to create and configure an application with Auth0 and update the `.env` file.

```text
ISSUER_BASE_URL=https://YOUR_DOMAIN
CLIENT_ID=YOUR_CLIENT_ID
API_URL=http://localhost:3001
PORT=3000
APP_SESSION_SECRET=LONG_RANDOM_STRING
```

::: note
If you changed the port for the API above, make sure to update the `API_URL` with this new value.
:::

7. Start the web application using npm:

```bash
❯ npm start

listening on http://localhost:3000
```

8. Open [localhost:3000](http://localhost:3000) in your browser. There, you will see the homepage of the web application and, if you log in, you will be able to access the expenses report. The page might look similar to the Lab 1 solution, however, the difference is that an external API provides the Expenses information instead of being hard-coded in the Web app.

![First page of the starter application](/media/articles/identity-labs/lab-02-starter-app-rendered.png)

Right now, even though the application requires authentication, the API does not. That is, you are calling the API from the Web app, without any authentication information. If you browse to the API's URL at [localhost:3001](http://localhost:3001) without logging in, you will see the expenses. In the following steps, you will update your application to call the API with a token.

9. Open `webapp/server.js` in your code editor and make the following change:

```js
// webapp/server.js

app.use(auth({
  required: false,
  auth0Logout: true,
  baseURL: appUrl,

  // Add the additional configuration keys below 👇
  appSessionSecret: false,
  authorizationParams: {
    response_type: 'code id_token',
    response_mode: 'form_post',
    audience: process.env.API_AUDIENCE,
    scope: 'openid profile email read:reports'
  },
  handleCallback: async function (req, res, next) {
    req.session.openidTokens = req.openidTokens;
    req.session.userIdentity = req.openidTokens.claims();
    next();
  },
  getUser: async function (req) {
    return req.session.userIdentity;
  }
  // 👆

}));
```

This change updates the configuration object passed to `auth()` and defines how you want the `express-openid-connect` library to behave. In this case, you configured the library with a new property called `authorizationParams` and passed in an object with three properties:

- `response_type` - setting this field to `code id_token` indicates that you no longer want the middleware to fetch just an ID token (which is the default behavior for this package). Instead, you are specifying that you want an ID token *and* an authorization code. When you configure the `express-openid-connect` library to fetch an authorization code, the middleware automatically exchanges this code for an access token (this process is known as the Authorization Code Grant flow). Later, you will use the access token to call the API.
- `response_mode` - This is the same mode used in lab 1, a POST request from the authorization server to the application.
- `audience` - this tells the middleware that you want access tokens valid for a specific resource server (your API, in this case). As you will see soon, you will configure an `API_AUDIENCE` environment variable to point to the identifier of an API that you will register with Auth0.
- `scope` - securing your API uses a delegated authorization mechanism where an application (your web app) requests access to resources controlled by the user (the resource owner) and hosted by an API (the resource server). Scopes, in this case, are the permissions that the access token grants to the application on behalf of the user. In your case, you are defining four scopes: the first three (`openid`, `profile`, and `email`) are scopes related to the user profile (part of OpenID Connect specification). The last one, `read:reports`, is a custom scope that will be used to determine whether the caller is authorized to retrieve the expenses report from the API on behalf of a user.

The `appSessionSecret`, `handleCallback`, and `getUser` additions change how the user session is handled and stores the incoming access and refresh tokens somewhere we can access later.

10. Back in the `webapp/server.js` file, find the `/expenses` endpoint definition. In this code, you are making a request to the API, without any authorization information, to get a JSON resource. Note the use of the `requiresAuth()` middleware. This will enforce authentication for all requests to this endpoint.

11. Update the endpoint definition to include authorization information in the request:

```js
// webapp/server.js

app.get('/expenses', requiresAuth(), async (req, res, next) => {
  try {

    // Replace this code ❌
    /*
    const expenses = await request(process.env.API_URL, {
      json: true
    });
    */

    // ... with the code below 👇
    let tokenSet = req.openid.makeTokenSet(req.session.openidTokens);
    const expenses = await request(process.env.API_URL, {
      headers: { authorization: "Bearer " + tokenSet.access_token },
      json: true
    });

    // ... keep the rest
  }
  // ...
});
```

In the new version of this endpoint, you are sending the access token in an `Authorization` header when sending requests to the API. By doing so, the web application consumes the API on behalf of the logged in user.

12. Add the following two environment variables to the `webapp/.env` file:

```text
API_AUDIENCE=https://expenses-api
CLIENT_SECRET=YOUR_APPLICATION_CLIENT_SECRET
```

The `API_AUDIENCE` value is the identifier for the API that will be created in the following exercise. To get your Client Secret, go to your Application settings page in the Auth0 Dashboard:

![Application client secret field](/media/articles/identity-labs/lab-02-client-secret-config.png)

**And that's it!** You have just configured your web application to consume the API on behalf of the logged in user.

If you restart the application in your terminal, logout, and try to log back in, you will see an error because no resource server with the identifier `https://expenses-api` has been registered yet. In the next exercise, you will learn how to create and secure APIs with Auth0, and this request will begin to work.

# Lab 2, Exercise 2: Securing APIs with Auth0

::: warning
If you came to this page directly, go to the [first page of this lab](/identity-labs/02-calling-an-api) and read through the instructions before getting started.
:::

In this exercise, you will register the API with Auth0 so that tokens can be issued for it. You will also learn how to secure your API with Auth0. You will refactor the API that your web application is consuming by installing and configuring some libraries needed to secure it with Auth0.

<div>
  <div>
    <ul class="nav nav-tabs">
      <li class="active">
        <a href="#video-tutorial" data-toggle="tab">
          Video Tutorial
        </a>
      </li>
      <li>
        <a href="#text-tutorial" data-toggle="tab">
          Lab
        </a>
      </li>
    </ul>
  </div>
  <div class="tab-content">
    <div id="video-tutorial" class="tab-pane active">
      <div class="video-wrapper" data-video="6omxlyo7w5"></div>
      <hr>
      <div class="video-wrapper" data-video="hkt0fbvxq3"></div>
      <hr>
    </div>
    <div id="text-tutorial" class="tab-pane">

1. To register the API with Auth0, open the Auth0 Dashboard and go to the [APIs screen](${manage_url}/#/apis).

2. Click the **Create API** button. Add a descriptive Name, paste `https://expenses-api` into the **Identifier** field, and click **Create**.

3. Click the **Permissions** tab and add a new permission called `read:reports` with a suitable description. This custom permission is the one you will use to determine whether the client is authorized to retrieve expenses.

4. In your terminal, restart your web application with `[CTRL]` + `[c]`, then `npm start`.

5. Log out of the web application by clicking [logout](http://localhost:3000/logout), then log in again. When logging in, you will see a consent screen where Auth0 mentions that the web application is requesting access to the read:reports scope:

![API consent screen on the authorization server](/media/articles/identity-labs/lab-02-api-consent-initial.png)

6. Agree to this delegation by clicking the **Accept** button, and Auth0 will redirect you back to the application. Now, you should still be able to see your expenses on the expenses page, [localhost:3000/expenses](http://localhost:3000/expenses):

![Application expenses page](/media/articles/identity-labs/lab-02-starter-app-rendered.png)

::: note
If at any point, you want to see the consent screen again when logging in, you can go to the Users screen in the Auth0 Dashboard, click on the user you'd like to modify, click the **Authorized Applications** tab, find the application you're using, and click **Revoke**. The next time you log in, the consent screen will appear again.
:::

As mentioned earlier, the expenses API is still not secure. You can see this by navigating directly to [localhost:3001](http://localhost:3001/). The expense data is available publicly, without an access token. The next steps will change the API to require a properly-scoped access token to view.

4. In your terminal, stop your API with `[CTRL]` + `[c]`.

5. Install the `express-oauth2-bearer` npm package. This is an Express authentication middleware used to protect OAuth2 resources, which validates access tokens:

```bash
# Make sure we're in the right directory
❯ pwd
/Users/username/identity-102-exercises/lab-02/begin/api

❯ npm install express-oauth2-bearer@0.4.0 --save
# Ignore any warnings

+ express-oauth2-bearer@0.4.0
added XX packages in X.XXs
```

6. Open the `api/api-server.js` file and add a statement to import the library. Make sure this is added after the dotenv require statement:

```js
// api/api-server.js

require('dotenv').config();
// ... other require statements

// Add the line below 👇
const { auth, requiredScopes } = require('express-oauth2-bearer');
```

7. Configure the Express app to use the authentication middleware for all requests:

```js
// api/api-server.js

// ... other require statements
const app = express();

// Add the line below 👇
app.use(auth());
```

8. Find the `/` endpoint code and update it to require the `read:reports` scope in access tokens. This is done by adding a `requiredScopes` middleware, as shown below:

```js
// lab-02/begin/api/api-server.js

// Change only the line below 👇
app.get('/', requiredScopes('read:reports'), (req, res) => {

    // ... leave the endpoint contents unchanged.

});
```

The next time you run your API, all requests that do not include a valid access token (expired token, incorrect scopes, etc.) will return an error instead of the desired data.

9. Open the `api/.env` file you created before and change the `ISSUER_BASE_URL` value to your own Auth0 base URL (same as the one in your application). The `.env` file should look like this:

```text
PORT=3001
ISSUER_BASE_URL=https://your-tenant-name.auth0.com
ALLOWED_AUDIENCES=https://expenses-api
```

10. Once again, start the API server with npm:

```bash
❯ npm start

listening on http://localhost:3001
```

To test your secured API, refresh the expenses page in your application - [localhost:3000/expenses](http://localhost:3000/expenses). If everything works as expected, you will still be able to access this view (which means that the web app is consuming the API on your behalf). If you browse directly to the API at [localhost:3001](http://localhost:3001), however, you will get an error saying the token is missing.

# Lab 2, Exercise 3: Working with Refresh Tokens

::: warning
If you came to this page directly, go to the [first page of this lab](/identity-labs/02-calling-an-api) and read through the instructions before getting started.
:::

<div>
  <div>
    <ul class="nav nav-tabs">
      <li class="active">
        <a href="#video-tutorial" data-toggle="tab">
          Video Tutorial
        </a>
      </li>
      <li>
        <a href="#text-tutorial" data-toggle="tab">
          Lab
        </a>
      </li>
    </ul>
  </div>
  <div class="tab-content">
    <div id="video-tutorial" class="tab-pane active">
      <div class="video-wrapper" data-video="lqriaseaxq"></div>
      <hr>
    </div>
    <div id="text-tutorial" class="tab-pane">

Right now, if your users stay logged in for too long and try to refresh the `/expenses` page, they will face a problem. Access tokens were conceived to be exchanged by different services through the network (which makes them more prone to leakage), so they should expire quickly. When an access token is expired, your API won't accept it anymore, and your web application won't be able to fetch the data needed. A token expired error will be returned instead.

To change this behavior, you can make your web app take advantage of yet another token: the refresh token. A refresh token is used to obtain new access tokens and/or ID tokens from the authorization server. In this exercise, we're going to modify the application to obtain a refresh token and use it to get a new access token when it expires.

1. Navigate to the [APIs screen](${manage_url}/#/apis) in your Auth0 Dashboard and open the API created in the last exercise. Scroll down, turn on the **Allow Offline Access** option, and click **Save**:

![Allow API to grant offline access](/media/articles/identity-labs/lab-02-api-allow-offline.png)

2. Now, Open the `webapp/server.js` file and add `offline_access` to the `authorizationParams.scope` field passed to the `auth()` middleware:

```js
// webapp/server.js

app.use(auth({
  required: false,
  auth0Logout: true,
  appSessionSecret: false,
  authorizationParams: {
    response_type: 'code id_token',
    response_mode: 'form_post',
    audience: process.env.API_AUDIENCE,

    // Change only the line below 👇
    scope: 'openid profile email read:reports offline_access'

  },

  // ... keep the rest

}));
```

3. Now, find the following line in the `/expenses` endpoint code and replace it with the following:

```js
// webapp/server.js

app.get('/expenses', requiresAuth(), async (req, res, next) => {
  try {

    let tokenSet = req.openid.makeTokenSet(req.session.openidTokens);

    // Add the code block below 👇
    if (tokenSet.expired()) {
      tokenSet = await req.openid.client.refresh(tokenSet);
      tokenSet.refresh_token = req.session.openidTokens.refresh_token;
      req.session.openidTokens = tokenSet;
    }

    // ... keep the rest
  }
  // ...
});
```

This change will update your endpoint to check if the `tokenSet` is expired. If it is, the `Issuer` class will create a client that is capable of refreshing the `tokenSet`. To see the refreshing process in action, you will have to make a small change to your Auth0 API configuration.

4. Navigate to the [APIs screen](${manage_url}/#/apis) in your Auth0 Dashboard and open the API created in the last exercise. Set both the **Token Expiration (Seconds)** and **Token Expiration For Browser Flows (Seconds)** values to 10 seconds or less and click **Save**:

![Access token expiration time](/media/articles/identity-labs/lab-02-api-token-expiration.png)

5. Back in your editor, add a log statement to `api/api-server.js` to show when the new access token was issued:

```js
// api/api-server.js

app.get('/', requiredScopes('read:reports'), (req, res) => {

  // Add the line below 👇
  console.log(new Date(req.auth.claims.iat * 1000));

  // ...
});
```

6. Restart both the application and API (`[CTRL]` + `[c]`, then `npm start`).

7. Log out and log in again. This will get you a complete set of tokens (ID token, access token, and refresh token). Note, at this point, you will see a new consent screen for the offline_access scope, which you need to accept.

Open [localhost:3000/expenses](http://localhost:3000/expenses) in your browser and refresh the page. You will see that your API logs a timestamp in the terminal. The same timestamp will be logged every time you refresh the page as long as your token remains valid. Then, if you wait a few seconds (more than ten) and refresh the view again, you will see that your API starts logging a different timestamp, which corresponds to the new token retrieved. This shows that you are getting a different access token every ten seconds and that your web application uses the refresh token automatically to get them.

::: note
If you see an error in your console about an ID token used too early, this is likely a clock skew issue in your local environment. Try restarting your machine and walking through the login steps again from the beginning. You can also try going to "Date & Time" settings, unlock them if needed by clicking on the lock icon at the bottom, and disable and re-enable the "Set date and time automatically" option.
:::

::: note
If you don't see changes in the "Issued At" claim in the console, make sure you have logged out and logged in again after applying the changes above.
:::

::: note
If you are using PowerShell in Windows and you see blank lines instead of the timestamp logging in the terminal, it could be the font color of the logs is the same as the background. As an alternative, you can run the API server from the Windows command line, or change the background color in PowerShell.
:::

🎉 **You have completed Lab 2 by building a web application that calls an API with refresh capability!** 🎉