# Lab 3: Mobile Native App

## Prerequisites

- Apple's [Developing iOS Apps: Build a Basic UI](https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/BuildABasicUI.html) tutorial to get a feeling of the Xcode's UI (optional)

## What You'll Need

**A Mac computer** - A Mac is required to install Xcode.

---

**An Apple account** - Required to download Xcode and install Xcode.

---

**Xcode** - Download and install Xcode from the App Store. After installation is complete, open it so that you go through the first-time setup, which can take up to 10 minutes. This will require around 6GB of hard drive space and up to 30 minutes total to complete.

---

**Node environment** - Install [Node.js](https://nodejs.org) directly or using [Homebrew](https://formulae.brew.sh/formula/node) or [NVM](https://github.com/nvm-sh/nvm) on a Mac. The labs were tested on Node.js v10.15.0 and NPM 6.4.1 (though they may work in other versions as well).

---

**An Auth0 account** - Sign up for a free Auth0 account [here](https://auth0.com/signup). We recommend starting with a new, empty tenant that can be deleted when you have completed the exercises. If you're using an existing test or dev tenant, make sure that all Rules are turned **off** and MFA is turned **off**.

---

**An Auth0 database user** - Use a new username/email and password user in a test database connection instead of a social, enterprise, or passwordless login. While social logins might work, using development keys can cause the labs to run differently. Choose a simple password that's easy to type as you will be logging in and out multiple times. You can use the same user across all of the labs.

---

**A web browser** - This lab was built and tested using Google Chrome; Safari, Firefox, and Edge should all work fine as well. Disable any active ad blockers used for the domain of your local site, as well as for the Auth0 domain from your tenant.

---

**For macOS users** - If you are new to macOS, check [these quick tips](https://blogs.mulesoft.com/dev/newbie/quick-tips-for-developers-new-to-mac/) for developers new to Mac. Make sure you allow the display of hidden files and become familiar with running basic commands in the terminal.

# Lab 3, Exercise 1: Adding Authentication

::: warning
If you came to this page directly, go to the first page of this lab and read through the instructions before getting started.
:::

In this exercise, you will add authentication to an existing iOS application. A simple iOS application has been provided to get you started. This is a single-view application with a button to launch the Auth0 authentication process.


1. Launch Xcode, go to **File > Open**, and open `/lab-03/exercise-01/begin/exercise-01.xcworkspace` in your locally-cloned copy of the identity exercise repo.

<%= include('../_includes/_git-clone-note') %>

::: note
If the project complains about a missing dependency, you might have opened `exercise-01.xcodeproj` instead of `exercise-01.xcworkspace` (note the extension).
:::

This project is a bare-bones application that imports the [Auth0.swift](https://github.com/auth0/auth0.swift) dependency to provide the OpenID Connect implementation. There is also a stub method called `actionLogin` for processing the touch of the login button.

2. In the bar at the top of the project window, click the device selector and pick a late-model iPhone, then click the Play button (or **Product > Run** from the Xcode menu) to run the app.

![Device simulator selection](/media/articles/identity-labs/lab-03-choose-device-and-run.png)

The simulator may take a few moments to load the first time, and then you should see the following:

![First time running iOS application](/media/articles/identity-labs/lab-03-first-run.png)

3. Touch the **Log In** button. This will output a "Log In" message to the Debug area in Xcode. If you don’t see the Debug view, you can enable it with **View > Debug Area > Show Debug Area**.

![iOS application debug console in Xcode](/media/articles/identity-labs/lab-03-first-debug-area.png)

4. Before any calls are made to the Auth0 authorization server, you need to set up a new Auth0 Application for handling Native Applications. Log into the Auth0 Dashboard, go to the [Applications page](${manage_url}/#/applications), and click the **Create Application** button.

5. Enter a descriptive name, select **Native** as the application type, and click **Create**.

6. Click on the **Settings** tab and scroll down to the **Allowed Callback URLs** field. Enter the value below (modified with your tenant domain):

```text
com.auth0.identity102://${account.namespace}/ios/com.auth0.identity102/callback
```

7. Scroll down and click **Show Advanced Settings**, then **OAuth**. Make sure **JsonWebToken Signature Algorithm** is set to `RS256`.

8. Click **Save Changes**

You might be wondering why the callback URL is in this format. There are two parts to this:

- The first element is the scheme of the application, which for the purposes of this exercise, is defined as `com.auth0.identity102`. Whenever Safari needs to handle a request with this scheme, it will route it to our application (you will set up this custom URL scheme URL later in the lab).
- The rest of the URL is in a format that the Auth0.swift SDK specifies for callbacks.

9. Now the sample iOS application needs to be configured with the **Client ID** and **Domain** values from the Auth0 Application. Return to Xcode and open the `exercise-01/Auth0.plist` file. You should see value placeholders for **ClientId** and **Domain**. Replace these with the values from the Auth0 Application created above.

![iOS application plist values](/media/articles/identity-labs/lab-03-plist.png)

::: note
The domain must not have any prefix like in the previous labs. Enter it exactly as it is provided in the Auth0 dashboard.
:::

To be able to use the callback that was configured in the Auth0 dashboard, a URL scheme handler needs to be registered in our iOS application so that it can respond to requests made to the callback URL.

10. In the file navigator on the left, click on `exercise-01` to open the project settings, then click on the **Info** tab.

![Project settings for iOS application](/media/articles/identity-labs/lab-03-project-settings-info-tab.png)

11. Scroll down to **URL Types**, expand the section, click the **+** button, and enter or select the following details:

- **Identifier**: `auth0`
- **URL Schemes**: `$(PRODUCT_BUNDLE_IDENTIFIER)`
- **Role**: `None`

Just as `http` is a URL Scheme that will launch a browser, the bundle identifier of the app has a URL Scheme (which will resolve to `com.auth0.identity102`) will tell iOS that any time this scheme is used in a URL, it must be routed to our application. That will be the case of the callback used by Auth0 after you log in.

12. Now, the application needs to have the Auth0.swift SDK handle the callback in order to proceed with the authentication flow. In the Project Navigator on the left, open `exercise-01/AppDelegate.swift` and add the following import statement just below the other one:

```swift
// exercise-01/AppDelegate.swift

import UIKit

// Add the line below 👇
import Auth0
```

13. In the same file, add the following method inside the `AppDelegate` class:

```swift
// exercise-01/AppDelegate.swift
// ...
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // Add the code below 👇
    func application(_
        app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any]
        ) -> Bool {
        return Auth0.resumeAuth(url, options: options)
    }

    // ... other existing methods
}
```

When another app requests a URL containing the custom scheme, the system will launch your app if necessary, bring it to the foreground, and call the method above. The iOS Framework provides the delegate method above for you to implement so that you can parse the contents of the URL and take appropriate action. In this case, you need this information to continue the authentication flow process. You will see later in this exercise why this step is needed.

Now that the iOS application is configured with your Auth0 application credentials and is able to receive and process callbacks, complete the following steps to see how to construct the OpenID Connect request to the authorization server.

14. Open `exercise-01/ViewController.swift` and add the following code inside the `actionLogin` method, after the line that prints the "Log In" message to the console:

```swift
// exercise-01/ViewController.swift
// ...
  @IBAction func actionLogin(_ sender: Any) {
      print("Log In")

      // Add the code below 👇
      Auth0
        .webAuth()
        .scope("openid profile email")
        .logging(enabled: true)
        .start { response in
            switch(response) {
                case .success(let result):
                    print("Authentication Success")
                    print("Access Token: \(result.accessToken ?? "No Access Token Found")")
                    print("ID Token: \(result.idToken ?? "No ID Token Found")")
                case .failure(let error):
                    print("Authentication Failed: \(error)")
                }
           }
  }
// ...
```

15. Run the app again by clicking the Play button (or **Product > Run** from the Xcode menu). Once the app has launched, touch the **Log In** button. You should see a permission prompt from iOS. Touch **Continue** to proceed to the Auth0 login page, which is rendered within a browser.

![Universal login page loaded](/media/articles/identity-labs/lab-03-login-confirmation.png)

16. Log in using your database user, and you will be taken back to the app. Nothing will have changed visually, but if you take a look at the Debug Area in Xcode you will see something like this:

```text
Authentication Success
Access Token: vxPp0Xtg3wkZJudFZWzqMQByYF98Qyer
ID Token: eyJ0eX[..].eyJodH[..].kLtZDg[..]
```

To view the contents of your ID Token, you can copy and paste it into [jwt.io](https://jwt.io/) to view the claims.

Now that you have an ID token, it's important to validate it to ensure that it can be trusted. A helper method `isTokenValid` is already included in the project; you can review its code in `Extras/Utils.swift` to learn how the validation is performed. It should be called after obtaining the token, to illustrate how it is used.

17. Back in the `actionLogin` method in `ViewController.swift`, add the line below:

```swift
// exercise-01/ViewController.swift
// ...

  @IBAction func actionLogin(_ sender: Any) {
      print("Log In")

      Auth0
        // ...
              case .success(let result):
                  // ... other print statements

                  // Add the line below 👇
                  print("ID Token Valid: \(isTokenValid(result.idToken!))")

              // ... failure case
      }
  }
// ...
```

18. Run the app again, log in, and take a look at the logs in Xcode. You should see an entry "ID Token Valid:" with the status of the validation (true or false).

Congratulations! You have successfully added Auth0 authentication to your native iOS app using an authorization code grant!

The authorization code grant by itself has some security issues when implemented on native applications. For instance, a malicious attacker can intercept the authorization code returned by Auth0 and exchange it for an access token. The Proof Key for Code Exchange (PKCE) is a technique used to mitigate this authorization code interception attack.

With PKCE, for every authorization request, the application creates a cryptographically random key called the **code verifier**, hashes that value into a **code challenge**, and sends the **code challenge** to the authorization server to get the authorization code. When the application receives the code after a successful login, it will send the code and the code verifier to the token endpoint to exchange them for the requested tokens.

Since you previously enabled logging in our `WebAuth` call with the `logging()` method, it is easy to see the process flow in the Debug Area.

19. Run the iOS Application, touch the **Log In** button, and then take a look at the Debug Area. The iOS application initiates the flow and redirects the user to the `/authorize` endpoint, sending the `code_challenge` and `code_challenge_method` parameters. It also sends a `response_type` of `code` (line breaks added below for readability):

```text
SafariAuthenticationSession:
https://${account.namespace}/authorize
?code_challenge=VsPaQ0gJjnluA2vwV0piY-D-DTCltGI9GbYkBNHvPHQ
&response_type=code
&redirect_uri=com.auth0.identity102://${account.namespace}/ios/com.auth0.identity102/callback
&state=RFnNyPj4NOZMUW8IpDBr-j3UgO4gCbhBZtLpWB_vmDo
&client_id=${account.clientId}
&scope=openid%20profile
&code_challenge_method=S256
&auth0Client=eyJzd2lmdC12ZXJzaW9uIjoiMy4wIiwibmFtZSI6IkF1dGgwLnN3aWZ0IiwidmVyc2lvbiI6IjEuMTMuMCJ9
```

20. Once again, enter your credentials and log in. Auth0 redirects the user back to the iOS application by calling the callback with the authorization code in the query string:

```text
iOS Safari:
com.auth0.identity102://${account.namespace}/ios/com.auth0.identity102/callback
?code=6SiMHrJHbG2aAPrj
&state=RFnNyPj4NOZMUW8IpDBr-j3UgO4gCbhBZtLpWB_vmDo
```

21. The Auth0.swift SDK will process the query string and send the authorization `code` and `code_verifier` together with the `redirect_uri` and the `client_id` to the token endpoint of the authorization server:

```text
POST /oauth/token

{"grant_type":"authorization_code",
"redirect_uri":"com.auth0.identity102:\/\/${account.namespace}\/ios\/com.auth0.identity102\/callback",
"code":"6SiMHrJHbG2aAPrj",
"code_verifier":"qiV8gYUrPco3qBlejLeZzgC9DMtXZY1GddzZpmVxyxw",
"client_id":"${account.clientId}"}
```

22. The authorization server validates this information and returns the requested access and ID tokens. If successful, you will see the following response containing your tokens:

```text
Content-Type: application/json

{"access_token":"ekhGPSE7xdhOTJuTo2dV-TYyJV-OTYrO",
"id_token":"eyJ0eX[..].eyJodH[..].1kZccn[..]",
"expires_in":86400,
"token_type":"Bearer"}
```

In the next exercise, you will use a token to validate and authorize the user and authorize against a protected API.


# Lab 3, Exercise 2: Calling a Secured API

::: warning
If you came to this page directly, go to the [first page of this lab](/identity-labs/03-mobile-native-app) and read through the instructions before getting started.
:::

In this exercise, you are going to enable the native application to authorize against the protected API backend that was built in [Lab 2, Exercise 2](/identity-labs/02-calling-an-api/exercise-02). In that lab, you set up an Auth0 API server for your Expenses API with an audience value of `https://expenses-api`.

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
      <div class="video-wrapper" data-video="g1r8exsdl4"></div>
      <hr>
    </div>
    <div id="text-tutorial" class="tab-pane">


If you have already completed lab 2, you can use the same Auth0 configuration and local files to run the API needed for this lab. Just go to `/lab-02/begin/api` in your locally-cloned copy of the [identity exercise repo](https://github.com/auth0/identity-102-exercises/) and run `npm start` in your terminal before beginning this exercise. Make sure your token expiration times in Auth0 are back to normal (at least an hour for both).

::: panel If you did not complete Lab 2
If you are doing this lab by itself, you can use the completed exercise sample code:

1. Go to `/lab-02/end/api` and run `npm install` in your terminal.

2. Follow steps 1-3 on [this page](/identity-labs/02-calling-an-api/exercise-02) to create an API in Auth0.

3. Create a copy of the `.env` file in the same directory as above, change the `ISSUER_BASE_URL` value to include your tenant name, and save the file.

4. Back in the terminal, run `npm start`.

```bash
# Starting from the Lab 3 begin folder...
❯ cd ../../../lab-02/end/api

❯ pwd
/Users/username/identity-102-exercises/lab-02/end/api

❯ cp .env-sample .env

❯ vim .env
# Change the ISSUER_BASE_URL value ...

❯ npm install

added XX packages in X.XXs

❯ npm start

listening on http://localhost:3001
```

:::

Regardless of which API codebase you're using, you should now be able to load [localhost:3001](http://localhost:3001/) in your browser and see an error saying `UnauthorizedError: bearer token is missing`.

5. For this exercise, we're going to open a different project in Xcode than the one we used in exercise 1. Go to **File > Open** in Xcode and select `lab-03/exercise-02/begin/exercise-02.xcworkspace` (make sure you pick the right file extension), then open `exercise-02/ViewController.swift`. This code picks up where the previous exercise left off and adds a new button to call the API.

6. Open the `exercise-02/Auth0.plist` file and replace the placeholder values for **ClientId** and **Domain** with the ones from the Auth0 Application created before.

7. Click the Play button (or **Product > Run** from the Xcode menu) to run the app.

![iOS application Call API button](/media/articles/identity-labs/lab-03-call-api-button.png)

8. Touch the **Call API** button, and you should see a "Call API" message in the Debug area in Xcode.

![Call API debug message in Xcode console](/media/articles/identity-labs/lab-03-call-api-debug-area.png)

You will now add code to make the API call from the mobile app. However, before doing so, you need to modify the authentication code to include the API's audience for authorization and the necessary scopes so that the required permissions are requested.

9. In the `actionLogin` method, which contains our authentication call, include the audience for the API we want to access. With this in place, there will be an additional audience inside the access token after successful authentication.

```swift
// exercise-02/ViewController.swift
// ...

    @IBAction func actionLogin(_ sender: Any) {
        Auth0
            .webAuth()
            .scope("openid profile")

            // Add the line below 👇
            .audience("https://expenses-api")

            // ...
        }
    }
// ...
```

10. Run the app from Xcode again, click **Log In**, and check the debug logs. You should see a block of output like below:

```text
Authentication Success
Access Token: eyJ0eXA[..].eyJpc3[..].XeiZaS[..]
ID Token: eyJ0eXA[..].eyJodH[..].Lv1TY8[..]
Token Valid: true
```

11. Copy and paste the value of the **Access Token** into [jwt.io](https://jwt.io). Notice the `scope` value of `openid profile`. In Lab 2, the additional scope `read:reports` was added, which is not present in the token yet:

```js
{
  "iss": "https://${account.namespace}/",
  "sub": "auth0|1234567890",
  "aud": [

    // New audience 👇
    "https://expenses-api",
    "https://${account.namespace}/userinfo"
  ],
  "iat": 1566840738,
  "exp": 1566840746,
  "azp": "${account.clientId}",

  // Existing scopes 👇
  "scope": "openid profile"
}
```

12. Now, add the `read:reports` scope to the parameter in the `scope()` method within `actionLogin`:

```swift
// exercise-02/ViewController.swift
// ...

  @IBAction func actionLogin(_ sender: Any) {
      Auth0
          .webAuth()

          // Replace this line ❌
          // .scope("openid profile")

          // ... with the line below 👇
          .scope("openid profile read:reports")

          // ...
      }
  }
```

13. Run the app again, log in, and check the access token in [jwt.io](https://jwt.io) once more. You should now see the `read:reports` scope in the payload. It’s time to make a call to the API!

14. To use the access token we obtained during login in the `actionAPI` method, you need a way to access this variable. Create a private variable in the `ViewController` class:

```swift
// exercise-02/ViewController.swift
// ...
import Auth0

class ViewController: UIViewController {

    // Add the line below 👇
    private var accessToken: String?

    // ...
}      
```

15. In the `.success` code block of the `actionLogin` method, set the new `accessToken` value to be what was returned from the token endpoint:

```swift
// exercise-02/ViewController.swift
// ...
    @IBAction func actionLogin(_ sender: Any) {
        // ...
                    case .success(let result):
                        // ...

                        // Add the line below 👇
                        self.accessToken = result.accessToken

                    case .failure(let error):
                        // ...
    }  
// ...   
```

16. In the `actionAPI` method in the same class, check that the user has authenticated and that you have an access token before making a call to the API:

```swift
// exercise-02/ViewController.swift
// ...
    @IBAction func actionAPI(_ sender: Any) {
        print("Call API")

        // Add the code below 👇
        guard let accessToken = self.accessToken else {
            print("No Access Token found")
            return
        }
    }
// ...
```

Here, you are assigning the class-scoped property `accessToken` to a local `accessToken` variable. If the class-scoped property is empty, an error will be returned.

17. Again in the `actionAPI` method, add the code below to start an API request:

```swift
// exercise-02/ViewController.swift
// ...
    @IBAction func actionAPI(_ sender: Any) {
        // ... code from above

        // Add the code below 👇
        let url = URL(string: "http://localhost:3001")!
        var request = URLRequest(url: url)
    }
// ...
```

::: note
If your API is running on a different port or URL, make sure to change that above.
:::

18. You also need a way to send the access token to the API. This is done by adding an HTTP Authorization request header:

```swift
// exercise-02/ViewController.swift
// ...
    @IBAction func actionAPI(_ sender: Any) {
        // ... code from above

        // Add the code below 👇
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.log()
    }
// ...
```

19. Finally, the request needs to be executed. You will use the functionality built into the iOS framework - `URLSession` - to perform the network operation:

```swift
// exercise-02/ViewController.swift
// ...
    @IBAction func actionAPI(_ sender: Any) {
        // ... code from above

        // Add the code below 👇
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
                print(response ?? "No Response")
        }
        task.resume() // Execute the request
    }
// ...
```

20. Let's try calling the API from our mobile app. Save your changes from above, run the app, and tap **Log In**. After successfully authenticating, tap the **Call API** button and check the logs in the Debug area for the API response:

```text
Call API
GET http://localhost:3001
Headers:
 Optional(["Authorization": "Bearer eyJ0eX[..].eyJpcM[..].dpN8sK[..]"])
<NSHTTPURLResponse: 0x6000010dfdc0> { URL: http://localhost:3001/ } { Status Code: 200, Headers {
    Connection =     (
        "keep-alive"
    );
    "Content-Length" =     (
        195
    );
    "Content-Type" =     (
        "application/json; charset=utf-8"
    );
    Date =     (
        "Tue, 27 Aug 2019 14:53:40 GMT"
    );
    Etag =     (
        "W/\"c3-oBamo6wQLwSzwYwQczXJ+w5tl5o\""
    );
    "X-Powered-By" =     (
        Express
    );
} }
```

The `Status Code: 200` (OK) lets us know the request was executed successfully. If you want to see it fail, simply comment out the line that adds the Authorization Bearer header, re-rerun the app, and try logging in again. You will see a `Status Code: 401` (Unauthorized).

21. You can see from the `Content-Length` header that there is a body in the response; output the raw data from the API by updating the `dataTask` closure with the following code:

```swift
// exercise-02/ViewController.swift
// ...
    @IBAction func actionAPI(_ sender: Any) {
        // ... code from above

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
                print(response ?? "No Response")

                // Add the code below 👇
                if let data = data {
                    print(String(data: data, encoding: .utf8) ?? "No Body")
                }
        }
        // ...
    }
// ...
```

22. Re-run the app, login, and call the API once more. You should now see the expenses in the debug area in Xcode:

```js
[{"date":"2019-08-27T15:02:04.838Z","description":"Pizza for a Coding Dojo session.","value":102},
{"date":"2019-08-27T15:02:04.838Z","description":"Coffee for a Coding Dojo session.","value":42}]
```

You have now integrated your native application frontend with a protected API backend! In the next exercise, you will look at how the access token can be refreshed without having the user go through the web-based authentication flow each time.

# Lab 3, Exercise 3: Working with Refresh Tokens

::: warning
If you came to this page directly, go to the [first page of this lab](/identity-labs/03-mobile-native-app) and read through the instructions before getting started.
:::

In this exercise, you will explore the use of refresh tokens. A refresh token is a special kind of token that can be used to obtain a renewed access token. You are able to request new access tokens until the refresh token is blacklisted. It’s important that refresh tokens are stored securely by the application because they essentially allow a user to remain authenticated forever.

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
      <div class="video-wrapper" data-video="vm4lx2twdh"></div>
      <hr>
    </div>
    <div id="text-tutorial" class="tab-pane">

For native applications such as our iOS application, refresh tokens improve the authentication experience significantly. The user has to authenticate only once, through the web authentication process. Subsequent re-authentication can take place without user interaction, using the refresh token.

1. Go to **File > Open** in Xcode and select `lab-03/exercise-03/begin/exercise-03.xcworkspace` (make sure you pick the right file extension), then open `exercise-03/ViewController.swift`. This code picks up where the previous exercise left off and adds a new button to refresh the access token.

2. Open the `exercise-03/Auth0.plist` file and replace the placeholder values for **ClientId** and **Domain** with the ones from the Auth0 Application created before.

3. Click the Play button (or **Product > Run** from the Xcode menu) to run the app. Touch the **Refresh Token** button and look for a “Refresh Token” message to the Debug area in Xcode.

![Refresh token button in iOS application](/media/articles/identity-labs/lab-03-refresh-token-button.png)

You are now going to add the `offline_access` scope, which gives the iOS application access to resources on behalf of the user for an extended period of time. Before you can use this scope, you need to make sure that Auth0 will allow applications to ask for refresh tokens for your API.

4. Navigate to the [APIs screen in your Auth0 Dashboard](${manage_url}/#/apis). Open the API that you created to represent your expenses API and ensure the **Allow Offline Access** option is on.

![Allow offline access for API](/media/articles/identity-labs/lab-03-allow-offline-access.png)

5. Next, we're going to add the `offline_access` scope to the authentication request. Open `exercise-03/ViewController.swift` and, in the `actionLogin` method, add `offline_access` to the `.scope()` method.

```swift
// exercise-03/ViewController.swift
// ...
  @IBAction func actionLogin(_ sender: Any) {
      Auth0
          .webAuth()

          // Replace this line ❌
          // .scope("openid profile read:reports")

          // ... with the line below 👇
          .scope("openid profile read:reports offline_access")

          // ...
      }
  }
// ...
```

6. Click the Play button (or **Product > Run** from the Xcode menu) to run the app. Log in again and check the Debug area in Xcode for the response.

```js
{
  "access_token":"3tjDJ3hsFOSyCr02spWHUhHNajxLRonv",

  // Here is the refresh token we asked for 👇
  "refresh_token":"sAvc4BJyOGs2I6Yc4e6r9NmReLp0kc-I6peiauDEt-usE",

  "id_token": "eyJ0eX[..].eyJodH[..].thhf0M[..]",
  "expires_in": 86400,
  "token_type": "Bearer"
}
```

7. We're going to send the refresh token to the authorization server using a `refresh_token` grant to get a new access token. In `ViewController.swift` and create a private variable in the `ViewController` class to create a way for `actionRefresh` method to access the refresh token.

```swift
// exercise-03/ViewController.swift
// ...
class ViewController: UIViewController {

   private var accessToken: String?

   // Add the line below 👇
   private var refreshToken: String?

   // ...
}
// ...
```

8. Assign the refresh token obtained during authentication to this private variable in the `.success` code block.

```swift
// exercise-03/ViewController.swift
// ...
    @IBAction func actionLogin(_ sender: Any) {
        // ...
                    case .success(let result):
                        // ...
                        self.accessToken = result.accessToken

                        // Add the line below 👇
                        self.refreshToken = result.refreshToken

                    case .failure(let error):
                        // ...
    }  
// ...   
```

9. In the `actionRefresh` method, check that the user has authenticated and that a refresh token is available before making any calls to the authentication API. In the code below, the class-scoped property `refreshToken` is assigned to a local `refreshToken` variable. If the class-scoped property is empty, an error will be returned.

```swift
// exercise-03/ViewController.swift
// ...
    @IBAction func actionRefresh(_ sender: Any) {
        print("Refresh Token")

        // Add the code below 👇
        guard let refreshToken = self.refreshToken else {
           print("No Refresh Token found")
           return
        }
    }
// ...   
```

10. The Auth0.swift SDK makes available a `.renew()` method, which takes a refresh token as a parameter and performs a call to the authorization server's token endpoint using the `refresh_token` grant. Add the following code to the `actionRefresh` method after the code from the previous step.

```swift
// exercise-03/ViewController.swift
// ...
    @IBAction func actionRefresh(_ sender: Any) {
        // ... code from the previous steps

        // Add the code below 👇
        Auth0
            .authentication()
            .logging(enabled: true)
            .renew(withRefreshToken: refreshToken)
            .start { response in
                switch(response) {
                    case .success(let result):
                          print("Refresh Success")
                          print("New Access Token: \(result.accessToken ?? "No Access Token Found")")
                          self.accessToken = result.accessToken
                    case .failure(let error):
                          print("Refresh Failed: \(error)")
                }
            }
    }
// ...   
```

11. Click the Play button (or **Product > Run** from the Xcode menu) to re-run the app. Tap **Log In** and, after successful authentication, touch the **Refresh Token** button. Look in the Xcode the debug area for the request. You should see a `POST` to the token endpoint, showing the refresh token grant in action.

```text
POST https://${account.namespace}/oauth/token HTTP/1.1
Auth0-Client: eyJuYW1lIjoiQXV0aDAuc3dpZnQiLCJ2ZXJzaW9uIjoiMS4xMy4wIiwic3dpZnQtdmVyc2lvbiI6IjMuMCJ9
Content-Type: application/json

{"grant_type":"refresh_token","client_id":"${account.clientId}","refresh_token":"2CNxaPe0UIkX_PZkLEkKuoAuRsP6Ycg81XR1jQlTyn1dt"}
```

12. Look for the response after the request above. You should see a response including a new `access_token`, new `id_token`, and a new `expires_in` time (some of the trace was omitted for brevity).

```text
HTTP/1.1 200
Content-Type: application/json
Date: Tue, 27 Aug 2019 16:25:26 GMT
x-ratelimit-remaining: 29
x-ratelimit-reset: 1566923126
x-ratelimit-limit: 30
Content-Length: 1923

{"access_token":"eyJ0eX[..].eyJpc3[..].Smqrd7[..]",
"id_token":"eyJ0eX[..].eyJua[..].Ff5Q5[..]",
"scope":"openid profile read:reports offline_access",
"expires_in":3600,"token_type":"Bearer"}
```

Notice that you don’t receive a new `refresh_token` in the response from the authorization server. The `refresh_token` from the initial authentication must be retained. Also, note that in the code added to the `actionRefresh` method the `access_token` received is stored in the `self.accessToken` class property. This is so the new access token can be used in other methods. If you try calling the API again, the request will be made with your new access_token.

Now that you are able to obtain a fresh access token by using the refresh token, it’s time to see what happens when a token expires.

13. Navigate to the [APIs screen in your Auth0 Dashboard](${manage_url}/#/apis) and open the expenses API. Set both the **Token Expiration** and the **Token Expiration For Browser Flows** fields to 10 seconds and save the changes.

14. In your app simulator, tap **Log In** to walk through the authentication process again and get a new access token with the shorter expiration. Immediately tap the **Call API** button to see the API call succeed.

15. Wait 10 seconds for the token to expire and click the **Call API** button again. You should see the API call fail with a `Status Code: 401` in the debug area.

```text
<NSHTTPURLResponse: 0x600001f34460> { URL: http://localhost:3001/ } { Status Code: 401, Headers {
    Date =     (
        "Tue, 27 Aug 2019 16:36:10 GMT"
    );
    "www-authentication" =     (
        "Bearer realm=\"api\", error=\"invalid_token\", error_description=\"invalid token\""
    );
} }
```

16. Tap **Refresh Token** and check the debug area to see the refresh token grant happen. Then, tap **Call API**, and you should get a `Status Code: 200` along with the expenses data again.

🎉 **You have completed Lab 3 by building a native mobile application calling a secure API with refresh capability!** 🎉