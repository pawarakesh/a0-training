# Lab 1: Web Sign-In

This lab covers the process for adding sign-in to a basic Node.js application. This lab is the same exercise we provide for new employees in a technical role here at Auth0.

::: warning
The Node OIDC npm package that this lab uses has not been tested, licensed, or officially released and should not be used in production.
:::


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


# Lab 1, Exercise 1: Adding Web Sign-In

::: warning
If you came to this page directly, go to the first page of this lab and read through the instructions before getting started.
:::

In this exercise, you will learn how to add sign-in to an app using:

- Node.js + Express
- An Express middleware to handle checking authentication and redirecting to login
- Auth0 as an Authorization Server

A simple Node.js Express application has been created to get you started. This is a web application with two pages. The first page, served under the root path `/`, shows “Hello World” and a link (“Expenses”) to the second page. The second page, served at `/expenses`, shows a table with expenses. At this point, these expenses are hard-coded; you will learn how to consume them from an API secured with Auth0 in the next lab.

1. Open your Terminal app, clone the identity exercise repo, then go to the `/lab-01/begin` folder:

```bash
❯ git clone https://github.com/Danco626/ao-training
Cloning into 'identity-102-exercises'...

❯ cd identity-102-exercises/lab-01/begin
```

2. Open a code editor like VS Code or Atom in the same directory (File > Open) and review the `server.js` code. This is a generic Node.js web application that uses `ejs` for views and `morgan` to log HTTP requests.

3. The `.env-sample` file will be used for the environment variables you need for this lab. It’s populated with a `PORT` (the port number where the app will run) and an `APP_SESSION_SECRET` (value used to encrypt the cookie data). You will set the other values later on in the lab. For now, create a copy of this file in the same folder and name it `.env`. Run the following commands in your terminal (or copy, paste, and rename the sample file in your editor):

```bash
# Make sure we're in the right directory
❯ pwd
/Users/username/identity-102-exercises/lab-01/begin

# Copy the .env-sample file to a new .env file that the app will use
❯ cp .env-sample .env
```

4. In your terminal, use `npm` to install all the dependencies and start the application:

```bash
❯ npm install
# Ignore any warnings

added XX packages in X.XXs
❯ npm start

listening on http://localhost:3000
```

::: note
If you see a message like "Error: listen EADDRINUSE :::3000" in your terminal after starting the application, this means that port 3000 is in use somewhere. Change the `PORT` value in your `.env` file to "4000" and try again.
:::

5. Open a Web browser and go to [localhost:3000](http://localhost:3000) (or `http://localhost:PORT` where PORT is the value of the environment variable, in case you changed its value). You should see a page with a “Hello World” message. Click the Expenses link to view the expenses page.

![First page of the starter app](/media/articles/identity-labs/lab-01-starter-app-rendered.png)

6. Now, we're ready to start adding authentication! Switch to your terminal window and press `[CTRL]` + `[c]` to stop the server, then use `npm` to install the package you'll use to secure the app. The `express-openid-connect` package is a simple Express middleware that provides OpenID Connect and JWT implementation.

```bash
# Continuing from previous terminal session ...
listening on http://localhost:3000
^C # Command to stop the server
❯ npm install express-openid-connect@1.0.2 --save
# Ignore any warnings

+ express-openid-connect@1.0.2
added XX packages in X.XXs
```

7. Next, update your application code to require `express-openid-client` in the `server.js` file:

```js
// lab-01/begin/server.js

require('dotenv').config();
// ... other required packages

// Add the line below 👇
const { auth } = require('express-openid-connect');

// ...
```

8. Now add the authentication middleware that will be used for all application routes:

```js
// lab-01/begin/server.js
// ...

const app = express();
app.set('view engine', 'ejs');
app.use(morgan('combined'));

// Add the code below 👇
app.use(auth({
  auth0Logout: true,
  baseURL: appUrl
}));

// ... other app routes
```

The middleware you installed automatically defines three routes in your application:

- `/login` - builds the OpenID Connect request and redirects to the authorization server (in this case, Auth0). For this to work properly, the middleware needs to include specific parameters with the request. You will configure these values using environment variables in the next step.
- `/callback` - handles the response from the authorization server, performs required validations like nonce, state, and token verification using the `openid-client` package, and sets the user in the session from the ID token claims.
- `/logout` - terminates the session in the application and redirects to Auth0 to end the session there as well.

The middleware will also augment Express’s request object with additional properties whenever the request is authenticated. For example, `req.openid.user` is a property that will contain user information.

::: note
The `auth0Logout: true` configuration key passed to `auth()` tells the middleware that, when the user logs out of the application, they should be redirected to a specific Auth0 URL to end their session there as well.
:::

The middleware needs to be initialized with some information to build a proper OpenID request and send it to the authorization server. This information includes:

- **The URL of the authorization server.** This URL will be used to download the OpenID Connect configuration from the discovery document, available at the URL `https://{your-auth0-domain}/.well-known/openid-configuration` ([here is the configuration](https://auth0.auth0.com/.well-known/openid-configuration) for the main Auth0 tenant). The discovery document is a standard OpenID Connect mechanism used to publish relevant discovery metadata of the OpenID Connect provider, including a link to what keys should be used for validating the tokens it issues.
- **The unique identifier for your application.** This is created on the authorization server and is a unique string that identifies your application. This identifier must be provided in each request, so the authorization server knows what application the authentication request is for.

You will use the Auth0 Dashboard to register your application with Auth0. Afterward, you’ll be able to retrieve the two values above and configure them as environment variables for your app. The middleware will read these environment variables and use them to build the request when a user tries to authenticate.

9. Log into the Auth0 Dashboard, go to the [Applications page](${manage_url}/#/applications), and click the **Create Application** button.

10. Set a descriptive name (e.g., "Identity Lab 1 - Web Sign In"), choose **Regular Web Applications** for the type, and click **Create**.

11. You should now see the Quickstart section that describes how to integrate Auth0 with a production application. Click the **Settings** tab at the top to see the Application settings.

12. Add your application’s callback URL - `http://localhost:3000/callback` (adjust the port number if needed) - to the **Allowed Callback URLs** field. Auth0 will allow redirects **only** to the URLs in this field after authentication. If the one provided in the authorization URL does not match any in this field, an error page will be displayed.

![Application callback URL field](/media/articles/identity-labs/lab-01-callback-url-config.png)

13. Next, add `http://localhost:3000` (adjust the port number if needed) to the **Allowed Logout URLs field**. Auth0 will allow redirects **only** to the URLs in this field after logging out of the authorization server.

![Application logout URL field](/media/articles/identity-labs/lab-01-logout-url-config.png)

14. Scroll down and click **Show Advanced Settings**, then **OAuth**. Make sure **JsonWebToken Signature Algorithm** is set to `RS256`.

15. Scroll down and click **Save Changes**

16. Open your `.env` file. Add `https://` to the **Domain** from Auth0 as the value for the `ISSUER_BASE_URL` key. Add the **Client ID** from Auth0 as the value for the `CLIENT_ID` key. Add a long, random string and the value for the `APP_SESSION_SECRET` key. You `.env` file should look similar to the sample below:

```
ISSUER_BASE_URL=https://your-tenant-name.auth0.com
CLIENT_ID=0VMFtHgN9mUa1YFoDx3CD2Qnp2Z11mvx
APP_SESSION_SECRET=a36877de800e31ba46df86ec947dab2fc8a2f7e1d23688ce2010cd076539bd28
PORT=3000
```

::: note
Mac users can enter the following in Terminal to get a random string suitable for the secret value: `openssl rand -hex 32`. This value is used by the session handler in the SDK to generate opaque session cookies.
:::

17. Save the changes to `.env` and restart the server as before, but do not open it in a browser yet.

Your app is now ready to authenticate with Auth0 using OpenID Connect! Before testing it, continue to the next exercise, where you will review the interactions that happen under the hood between your app and Auth0 while you sign up and log in.

```bash
# Continuing from previous terminal session ...
listening on http://localhost:3000
^C # Command to stop the server
❯ npm start

listening on http://localhost:3000
```


# Lab 1, Exercise 2: Using Network Traces

::: warning
If you came to this page directly, go to the first page of this lab and read through the instructions before getting started.
:::

In this exercise, you will sign up for your application (which will also log you in) while exploring some of the relevant network traces of the authentication process.

1. Using Chrome, open **Developer Tools**. Switch to the **Network** tab then open your local application. You should immediately be redirected to Auth0 to login.

2. The first request you should see is a GET request to your application homepage:

![Network request for application homepage](/media/articles/identity-labs/lab-01-network-trace-01.png)

3. After that, you should see a GET request to `https://your-tenant-name.auth0.com/authorize`. This is the middleware added in exercise 1 taking over. The middleware checks if the user is logged in and, because they are not, it builds the OpenID Connect request to the authorization server URL and forwards the user to it. In this case, the complete GET request URL will look something like this (line breaks added for clarity):

```text
https://YOUR_DOMAIN/authorize
?client_id=YOUR_CLIENT_ID
&scope=openid%20profile%20email
&response_type=id_token
&nonce=71890cc63567e17b
&state=85d5152581b310e3389b
&redirect_uri=http%3A%2F%2Flocalhost%3A3000
&response_mode=form_post
```

---

The middleware sends several parameters. The important ones for this lab are:

- `client_id`: the unique identifier of your app at the authorization server
- `response_type`: the requested artifacts; in this case, you are requesting an ID token
- `scope`: why the artifacts are required, i.e. what content and capabilities are needed
- `redirect_uri`: where the results are to be sent after the login operation, i.e. the callback URL.
- `response_mode`: how the response from the server is to be sent to the app; in this case, the response we want is a POST request.

![Network request for authorization server](/media/articles/identity-labs/lab-01-network-trace-02.png)

::: note
If you scroll down while on the **Headers** tab in Chrome Developer Tools to the **Query String Parameters** section, you can see the different URL parameters in a more-readable table format.
:::

4. If you already have a user created, enter your credentials and continue below. If not, click the **Sign Up** link at the bottom (if you're using the classic page, this will be a tab at the top) and enter an email and password.

5. A consent dialog will be shown requesting access to your profile and email. Click the green button to accept and continue.

6. The authorization server will log you in and POST the response - an error if something went wrong or the ID token if not - back to the callback URL for your application. Once you’ve successfully logged in, you should see your user name on the page. This means authentication has been configured properly!

![Network request for application callback](/media/articles/identity-labs/lab-01-network-trace-03.png)

The complete trace of the callback request is:

```text
Request URL: `http://localhost:3000/callback`
Request Method: POST
Status Code: 302 Found
Remote Address: [::1]:3000
Referrer Policy: no-referrer-when-downgrade
Connection: keep-alive
Content-Length: 46
Content-Type: text/html; charset=utf-8
Date: Mon, 12 Nov 2018 23:00:08 GMT
Location: /
Set-Cookie: identity102-lab=eyJyZX[..]; path=/; httponly
Set-Cookie: identity102-lab.sig=wld5z7[..]; path=/; httponly
Vary: Accept
X-Powered-By: Express
id_token: eyJ0eX[..].eyJuaW[..].IEpcS5[..]
state: 85d5152581b310e3389b
```

::: note
If you see an error in your console about an ID token used too early, this is likely a clock skew issue in your local environment. Try restarting your machine and walking through the login steps again from the beginning.
:::

7. Click on the callback request, then search for the Form Data section of the Headers tab of the Developer Console. Copy the complete `id_token` value.

![Network request for ID token form post](/media/articles/identity-labs/lab-01-network-trace-04.png)

8. Go to [jwt.io](https://jwt.io) and paste the ID token copied from the last step into the text area on the left. Notice that as soon as you paste it, the contents of the text area on the right are updated. This is because the site decodes your ID token and displays its contents (claims) in that panel.

![Decoded ID token](/media/articles/identity-labs/lab-01-id-token-in-jwt-io.png)

Note the following:

- The token structure: it consists of the header (information about the token), the payload (the token’s claims and user profile information), and the signature.
- The claim `iss` is for the issuer of the token. It denotes who created and signed it. The value should match your Auth0 Domain value with an `https://` prefixed.
- The claim `sub` is the subject of the token. It denotes to whom the token refers. In our case, the value matches the ID of the Auth0 user.
- The claim `aud` is the audience of the token. It denotes for which app the token is intended. In our case, this matches the Client ID of the application that made the authentication request.
- The claim `iat` shows when the token was issued (seconds since Unix epoch) and can be used to determine the token’s age.
- The claim `exp` shows when the token expires (seconds since Unix epoch).

🎉 **You have completed Lab 1 by building a web application with sign-on using OpenID Connect!** 🎉






