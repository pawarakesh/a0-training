
# Lab 4: Single Page App

## Prerequisites

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


# Lab 4, Exercise 1: Adding Sign On

::: warning
If you came to this page directly, go to the [first page of this lab](/identity-labs/04-single-page-app) and read through the instructions before getting started.
:::

In this lab, you will learn how to add sign-on capabilities to a Single-Page Application (SPA) and how to make this app consume an API that is secured with Auth0. You will integrate the SPA with Auth0 so that your users are able to use the Auth0 Universal Login Page to authenticate.

The SPA in question is a vanilla JavaScript application that consumes an API similar to the one you have used in previous labs (this API also exposes a secured endpoint that returns a list of expenses). The difference is that the API in this lab does two additional things:

- The API supports CORS to enable the SPA to consume it from a different domain (or a different port in a local environment).
- The API exposes a public endpoint that returns a summary of its database. The SPA consumes this endpoint on its homepage to share the summary publicly.

In this exercise, you will focus on integrating the SPA with Auth0 and getting the profile of the logged-in user. Exercise 2 will show how to consume the private endpoint exposed by the API.


1. First, you will run a version of the app that is not integrated with Auth0. Open a new terminal and browse to `/lab-04/exercise-01/begin/api` in your locally-cloned copy of the [identity exercise repo](https://github.com/auth0/identity-102-exercises/). This is where the code for your API resides. Install the dependencies using npm.

```bash
# Make sure we're in the right directory
❯ pwd
/Users/username/identity-102-exercises/lab-04/exercise-01/begin/api

❯ npm install
# Ignore any warnings

added XX packages in X.XXs
```

2. Make a copy of the `.env-sample` file and name it `.env`.

```bash
❯ cp .env-sample .env
```

3. Edit the new `.env` file to add your tenant domain and save the file.

```text
PORT=3001
ISSUER_BASE_URL=https://${account.namespace}
ALLOWED_AUDIENCES=https://expenses-api
```

4. Run the API:

```bash
❯ npm start
```

5. Open a new terminal in the `/lab-04/exercise-01/begin/spa` folder and run `http-server` to host the SPA.

```bash
# Navigating from the previous directory
❯ cd ../spa

# Make sure we're in the right directory
❯ pwd
/Users/username/identity-102-exercises/lab-04/exercise-01/begin/spa

❯ npx http-server . -p 5000 -c-1
npx: installed 26 in 3.459s
Starting up http-server, serving .
Available on:
  http://127.0.0.1:5000
  http://10.10.10.10:5000
  http://192.168.1.4:5000
Hit CTRL-C to stop the server
```

::: note
On the command above, `-p 5000` makes the server listen on port 5000, and `-c-1` makes browsers ignore their own cache. This last parameter is important to facilitate the development process.
:::

6. Open [localhost:5000](http://localhost:5000) in a web browser, and you should see the page below. If you do not see the App Summary section, make sure your API is properly running at port 3001.

![Initial load for single-page application](/media/articles/identity-labs/lab-04-initial-load.png)

This is the homepage of your SPA. Right now, this SPA has no integration with Auth0. Also, the app is only consuming the public endpoint provided by the API. This endpoint returns two pieces of information: the total number of expenses recorded in the database (two, in this case), and the sum of their amount ($144.00). The SPA is using this information to feed the "App Summary" section of the page you are seeing.

7. To register this SPA with Auth0, log into the Auth0 Dashboard, go to the [Applications page](${manage_url}/#/applications), and click the **Create Application** button.

8. Set a descriptive name (e.g., "Identity Lab 4 - Single Page App"), choose **Single Page Web Application** for the type, and click **Create**.

9. You should now see the Quickstart section that describes how to integrate Auth0 with a production application. Click the **Settings** tab at the top to see the Application settings.

10. Add `http://localhost:5000/#callback` to the **Allowed Callback URLs** field. Auth0 will allow redirects **only** to the URLs in this field after authentication. If the one provided in the authorization URL does not match any in this field, an error page will be displayed.

11. Add `http://localhost:5000` to the **Allowed Web Origins** field. This field defines what URLs will be able to issue HTTP requests to Auth0 during a [silent authentication process](https://auth0.com/docs/api-auth/tutorials/silent-authentication). Your SPA will leverage this mechanism to check whether the current browser has an active session on the Auth0 authorization server.

12. Add `http://localhost:5000` to the **Allowed Logout URLs** field. Auth0 will allow redirects **only** to the URLs in this field after logging out of the authorization server.

13. Scroll down and click **Show Advanced Settings**, then **OAuth**. Make sure **JsonWebToken Signature Algorithm** is set to `RS256`.

14. Scroll down and click **Save Changes**

Now that you have registered your SPA with Auth0, you can update your code to integrate both. Below is a summary of the steps you will execute:

- Import [auth0-spa-js](https://github.com/auth0/auth0-spa-js) and configure it with your own Auth0 settings.
- Add code to handle the authentication callback.
- Add code to restrict content to authenticated users only.
- Implement login and logout.
- Obtain and display user profile information.

The [auth0-spa-js](https://github.com/auth0/auth0-spa-js) SDK is a simple, lightweight, and opinionated client developed by Auth0 that executes the OAuth 2.0 Authorization Code Grant Flow with PKCE. This client allows developers to quickly and securely implement authentication in their browser-based applications.

15. Open the `spa/index.html` file and search for the `<script>` tag that imports app.js. Right before that tag, add the auth0-spa-js library to your SPA using the CDN-hosted link.

```html
<!-- spa/index.html -->
<!-- ... -->

    <!-- Add the tag below 👇 -->
    <script src="https://cdn.auth0.com/js/auth0-spa-js/1.1.1/auth0-spa-js.production.js"></script>

    <script src="app.js"></script>
  </body>
</html>
```

16. Open `spa/app.js`. This file contains the code that starts your SPA in the browser. At the top of it, you will see several constants that reference DOM elements. Right after those definitions, add the variable declaration to allow `auth0Client` to be used globally.

```js
// spa/app.js
// ... other constants
const loadingIndicator = document.getElementById('loading-indicator');

// Add the line below 👇
let auth0Client;
```

17. In the `window.onload` function, add the code that configures the auth0-spa-js library with your own Auth0 details. Replace both placeholders with the **Domain** and **Client ID** properties for your SPA Application in Auth0.

```js
// spa/app.js
// ...

window.onload = async function() {
  let requestedView = window.location.hash;

  // Add the code below 👇
  auth0Client = await createAuth0Client({
    domain: '${account.namespace}',
    client_id: '${account.clientId}'
  });

  // ...
};
```

18. Implement the authentication callback after the snippet above in the `window.onload` function.

```js
// spa/app.js
// ...

window.onload = async function() {
  // ... code from the previous step

  // Add the code below 👇
  if (requestedView === '#callback') {
    await auth0Client.handleRedirectCallback();
    window.history.replaceState({}, document.title, '/');
  }

  // ...
};
```

The `requestedView` variable is used to identify if the request in question refers to a user coming back from the authentication process (i.e., if this is a user being redirected back to the application by Auth0 after authenticating).

19. Restrict site content to authenticated users only by finding the `allowAccess` function definition (at the bottom of the file) and replacing it with an authentication check.

```js
// spa/app.js
// ...

/* Replace the code below ❌
async function allowAccess() {
  await loadView('#home', content);
  return false;
}
*/

// ... with this 👇
async function allowAccess() {
  if (await auth0Client.isAuthenticated()) {
    return true;
  }
  await loadView('#home', content);
  return false;
}
```

The goal of this function is to allow or deny access to whatever route calls it. This function is called from the `#expenses` route to ensure the user is logged in. Although you won't use that route on this exercise (only on the next one), you can check the code in the `spa/scripts/expenses.js` file. The previous version of this function was hardcoded always to deny access and redirect to the #home route because no authentication mechanism was in place yet.

You are now making use of the `isAuthenticated()` method provided by the SPA SDK to block unauthenticated users from accessing the route calling this function. If an anonymous user tries to access it, the app will detect that they are not authenticated and will redirect them back to the homepage.

20. To give users a way to log in and view restricted content, open the `spa/scripts/navbar.js` file. There, you will see the definition of a few constants within the `async function()` [IIFE](https://developer.mozilla.org/en-US/docs/Glossary/IIFE). Below that, we'll add code to handle a click event on the login button.

```js
// spa/scripts/navbar.js
(async function() {
  // ... other constants
  const logOutButton = document.getElementById('log-out');

  // Add the code below 👇
  logInButton.onclick = async () => {
    await auth0Client.loginWithRedirect({
      redirect_uri: 'http://localhost:5000/#callback'
    });
  };

})();
```

The logInButton button will now, when clicked, invoke the `loginWithRedirect()` method provided by the SPA SDK to start the authentication process. When users click the login button, they will be redirected to the authorization server.

The `redirect_uri` property passed to the `loginWithRedirect()` method defines the URL that Auth0 must call after the authentication phase is concluded. This is the same URL listed in the **Allowed Callback URLs** field in the Auth0 Dashboard. If you use another URL without whitelisting it first, Auth0 will show an error page.

21. To define what happens when users click the logout button, add the code below right after the code from the previous step in the same function.

```js
// spa/scripts/navbar.js
(async function() {
  // ... code from the previous example

  // Add the code below 👇
  logOutButton.onclick = () => {
    auth0Client.logout({
      returnTo: 'http://localhost:5000'
    });
  };

})();
```

In this case, you are making the `logOutButton` button invoke the `logout()` method provided by the SPA SDK to end the user's Auth0 session. The `returnTo` property passed to this method works similar to the `redirect_uri` passed to the `loginWithRedirect()` method. This logout return URL was whitelisted in your Auth0 Application using the **Allowed Logout URLs** field.

22. Now, you will implement the behavior in your application that depends on whether the user is authenticated or not. After the code from the previous step, add the following code:

```js
// spa/scripts/navbar.js
(async function() {
  // ... code from the previous example

  // Add the code below 👇
  const isAuthenticated = await auth0Client.isAuthenticated();
  if (isAuthenticated) {
    const user = await auth0Client.getUser();
    profilePicture.src = user.picture;
    userFullname.innerText = user.name;

    logOutButton.style.display = 'inline-block';
  } else {
    logInButton.style.display = 'inline-block';
  }

})();
```

You defined a flag called `isAuthenticated` that defines if the user is authenticated or not. If they are authenticated, you use the `getUser()` method provided by the SPA SDK to extract their profile details. These details populate the screen with the name of the user and their picture.

The `isAuthenticated` flag also defines what button the app will show based on their authentication status: the `logInButton` or the `logOutButton`. If the user has a session with this application, the app will show the `logOutButton` button. Otherwise, it will show the `logInButton`.

23. Save all your changes and refresh the browser. You will see a screen that is slightly different from the previous one.

![Login button for single-page application](/media/articles/identity-labs/lab-04-login-button-showing.png)

24. In this new screen, click the **Log In** button to start the authentication process. Log in with your database user and accept the consent request. After successful authentication, Auth0 will redirect you back to your app, and your profile details (username and picture) will be shown near the upper-right corner:

![Login complete on single-page application](/media/articles/identity-labs/lab-04-login-complete.png)

::: note
If you log in using a social identity provider (Google, Facebook, etc.), you will need to log in every time you refresh the SPA. This happens because you are using Auth0’s test development keys for the identity provider. To prevent this from happening, you would need to register your application with the relevant Identity Provider and replace the test development keys on the Auth0 dashboard with your own. However, for the purposes of this lab, you should log in with a username and password to avoid the aforementioned behavior.

For more information, see [Test Social Connections with Auth0 Developer Keys](https://auth0.com/docs/connections/social/devkeys).
:::

If you want to test the `allowAccess()` function, which restricts access for particular routes depending on whether the user is authenticated, try navigating to [localhost:5000/#expenses](http://localhost:5000/#expenses). If you are logged in, the page will load successfully showing a "Loading..." text (the content for this page will be implemented in the next exercise). If you are not logged in, the app will redirect you to the homepage.

25. Let's explore the relevant network traces of the authentication process used in this lab. First, click the **Log Out** button, then, once you return to the app with your session ended, open Chrome's **Developer Tools** and go to the **Network** tab.

26. Click the **Log In** button. The first thing you will see in **Developer Tools** is a request similar to this:

```text
https://${account.namespace}/authorize?client_id=...
```

This request is created and triggered by the SPA SDK when a user clicks on the login button. If you check the query parameters passed alongside this URL, you will find, among others, the following:

- `client_id` - the unique identifier of your application for the authorization server.
- `response_type` - the artifacts needed to authenticate the user in your application. In this case, the SPA SDK is requesting an authorization code. This indicates to Auth0 that you will be using the [Authorization Code Grant Flow](https://auth0.com/docs/api-auth/tutorials/authorization-code-grant) (as defined by the OAuth 2.0 specification).
- `scope` - a space-delimited list of permissions that the application requires. In this case, your app is requesting `openid profile email`. These are scopes defined by the [OpenID Connect specification](/scopes/current/oidc-scopes) and give your app access to specific data in the user profile.
- `code_challenge` - this is a code that the authorization server will store and associate with the authorization request. In a future step, before issuing tokens to your application, the authorization server will use this code to verify (against another code called `code_verifier` that is handled internally by the SPA SDK) if it is secure to issue tokens. By using the code challenge and verifier, the SPA SDK is making the authorization process use a variant of the Authorization Code Grant Flow called PKCE.

27. Log in again by clicking **Log In**. After Auth0 redirects back to your application, check the **Network** tab in  **Developer Tools**, and you will see a list of requests, starting with the callback. Filter the requests and show only the XHR ones (those generated by an XMLHttpRequest JavaScript object).

28. Click on the "token" request (if there are two, click the second one). You will see that it is a `POST` request to the token endpoint of the authorization server. This request exchanges the code retrieved on the authentication process for the tokens needed in your application.

29. To see the data sent to the token endpoint, scroll to the bottom of the **Headers** tab. There, you will see that the request payload includes the following fields: `client_id`, `code`, `code_verifier`, `grant_type`, and `redirect_uri`.

![Network request for token endpoint POST](/media/articles/identity-labs/lab-04-token-ep-post.png)

30. Switch to the **Preview** tab to see the tokens returned by the authorization server.

![Network response from token endpoint POST](/media/articles/identity-labs/lab-04-token-ep-response.png)

::: note
If you are using a content blocker or browser setting that blocks third-party cookies, you will notice that in the step below, when authenticated, you need to log in again after refreshing the page. In that case, try changing your content blocker settings to allow your Auth0 domain (or turning it off altogether for localhost). Blocking all third-party cookies is not generally recommended as it is known to cause issues in some Web sites. This problem does not occur when [Custom Domains](/custom-domains) are used.
:::

31. If you refresh the SPA and change **Developer Tools** to filter requests by Doc (Documents), you will see a request called `authorize`. This request is similar to the one issued after the authentication process with a few differences:

- The request uses a different `response_mode`, in this case `web_message`. This is part of a strategy used to [renew tokens silently](/api-auth/tutorials/silent-authentication#renew-expired-tokens).
- The request defines a new query parameter called `prompt` set to `none`. As defined in the OpenID Connect protocol, this parameter is used on [authentication requests that must not display user interaction](https://auth0.com/docs/api-auth/tutorials/silent-authentication). This parameter is also part of the silent authentication process.

![Silent authentication network request from single-page application](/media/articles/identity-labs/lab-04-silent-auth-request.png)

For this to work properly, the silent authentication process requires the referrer URL to be whitelisted. This is why you added `http://localhost:5000` to the **Allowed Web Origins** field for your Auth0 Application. Otherwise, the silent authentication process would fail, and your users would need to log in again interactively.

# Lab 4, Exercise 2: Calling a Protected API

::: warning
If you came to this page directly, go to the [first page of this lab](/identity-labs/04-single-page-app) and read through the instructions before getting started.
:::

In this exercise, you will learn how to make your SPA consume, on behalf of the user, the private endpoint exposed by the API.

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
      <div class="video-wrapper" data-video="a9o2c59weh"></div>
      <hr>
    </div>
    <div id="text-tutorial" class="tab-pane">

::: note
You can continue using the source code from the previous exercise, or if you are starting from scratch, use the code in the `exercise-02/begin` folder. Make sure you run steps 1-6 in [exercise 1](/identity-labs/04-single-page-app/exercise-01) either way.
:::

To make your SPA consume the private endpoint on the user's behalf, it must fetch an access token first, then call the protected API. The first time your application asks for an access token for an API, the authorization server will request explicit consent from your users.

To request this consent, your application will open a popup that will load a page from the authorization server. On that page, your users will learn what type of access your application is requesting, and they will be able to grant access or deny it.

1. Open `spa/scripts/expenses.js`. You will see a few constants that reference DOM elements (like `loadExpensesButton` and `loadingExpenses`). Right after these constants, add the configuration code for the API.

```js
// spa/scripts/expenses.js
(async function() {
  // ... other constants
  const loadingExpenses = document.getElementById('loading-expenses');

  // Add the code below 👇
  const expensesAPIOptions = {
    audience: 'https://expenses-api',
    scope: 'read:reports',
  };

  // ...
})();
```

The `expensesAPIOptions` constant is a configuration object that will tell the SPA SDK the audience and scope needed in the access token your application will request. The SDK will try to fetch access tokens capable of consuming the `https://expenses-api` API with the `read:reports` scope.

2. Request the access token required to retrieve the expenses from the protected API on behalf of the user with the code below.

```js
// spa/scripts/expenses.js
(async function() {
  // ... code from the previous example

  // Add the code below 👇
  try {
    const accessToken = await auth0Client.getTokenSilently(expensesAPIOptions);
    await loadExpenses(accessToken);
  } catch (err) {
    if (err.error !== 'consent_required') {
      alert('Error while fetching access token. Check browser logs.');
      return console.log(err);
    }

    loadExpensesButton.onclick = async () => {
      accesstoken = await auth0Client.getTokenWithPopup(expensesAPIOptions);
      await loadExpenses(accesstoken);
    };

    consentNeeded.style.display = 'block';
    loadExpensesButton.style.display = 'inline-block';
    loadingExpenses.style.display = 'none';
  }

  // ...
})();
```

The lines above are nested inside a `try/catch` block and are executed when the expenses view is requested. First, the application calls the `getTokenSilently()` method (provided by the SPA SDK) to see if your application is able to fetch a token without involving your user. If your app fetches the access token successfully, the application calls the `loadExpenses()` function with this token to load and display expenses (you will define this function in the next step).

If your application is not able to fetch an access token (an error occurs, or the user is not logged in), the application checks if the problem is `consent_required`, which means that the user has not given consent to access the API yet. If that is not the case, it means an unknown error has been raised, and your application will alert the user and log the error to the browser’s console.

If `consent_required` is indeed the problem, then you define the behavior of the `loadExpensesButton` and show the `consentNeeded` and `loadExpensesButton` DOM elements. These DOM elements are responsible for letting the user know that they will need to give your application explicit consent to consume the API on their behalf. More specifically, after reading the message, if your users click the `loadExpensesButton`, your application will trigger the SDK-provided `getTokenWithPopup()` method to open a popup where your users will be able to give consent.

3. Call the API using the access token with the code below.

```js
// spa/scripts/expenses.js
(async function() {
  // ... code from the previous example

  // Add the code below 👇
  async function loadExpenses(accesstoken) {
    try {
      const response = await fetch('http://localhost:3001/', {
        method: 'GET',
        headers: { authorization: 'Bearer ' + accesstoken }
      });

      if (!response.ok) {
        throw 'Request status: ' + response.status;
      }

      const expenses = await response.json();
      displayExpenses(expenses);
    } catch (err) {
      console.log(err);
      alert('Error while fetching expenses. Check browser logs.');
    }
  }

  // ...
})();
```

After fetching an access token (silently or explicitly through the popup), your application will invoke the function above to issue a request to the private API on the user's behalf. Note the `authorization` header passed to the `fetch()` function; this header includes the access token required to consume the expenses API.

After executing the request to the API, if successful, the `displayExpenses()` function is called. This function creates the DOM elements on the page to represent the expenses and is already defined in the `spa/scripts/expenses.js` file at the bottom.

4. Open `spa/scripts/navbar.js` and search for the block that gets executed when the user `isAuthenticated`. Inside this block, right after changing the display property of the `logOutButton`, add the code below. This will display a link to the expenses view in the navigation bar when the user is authenticated.

```js
// spa/scripts/navbar.js
(async function() {
  // ... code from the previous example

  const isAuthenticated = await auth0Client.isAuthenticated();
  if (isAuthenticated) {
    // ...

    // Add the line below 👇
    expensesLink.style.display = 'inline-block';
  } // ...

})();
```

5. You are now ready to test the new version of the application. Save all the changes and reload the application in your browser. You should see the **Expenses** link in the navigation bar at the top.

![Expenses link on single-page application](/media/articles/identity-labs/lab-04-expenses-link-showing.png)

6. Click **Expenses** link, and you should see the consent prompt.

![Consent link on single-page application](/media/articles/identity-labs/lab-04-consent-link-showing.png)

7. Because you have not provided consent yet, you will see an **Allow App to Load Expenses** button. Clicking it will open the consent popup; note that the **Reports** scope is now included.

![Consent prompt on single-page application](/media/articles/identity-labs/lab-04-consent-prompt.png)

In the popup, click the **Accept** button to give consent. The popup will close, and your application will get the access token it needs. With this token, the SPA will call the `loadExpenses()` function and show the data retrieved from the API.

![Expenses API data loading in single-page application](/media/articles/identity-labs/lab-04-expenses-data-showing.png)

::: note
If you want to recreate the scenario where consent is needed, go to the [Users screen of the Auth0 Dashboard](${manage_url}/#/users), view your test user, click the **Authorized Applications** tab, and click **Revoke** for the single-page application with the Expenses API audience.

![Revoke application permission for an API](/media/articles/identity-labs/lab-04-revoke-app.png)
:::

🎉 **You have completed Lab 4 by building a single-page application calling a secure API!** 🎉