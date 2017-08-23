# Alamofire & Realm Demo

This is a step-by-step walkthrough of my talk at [CocoaHeads Sthlm, April 3 2017](https://www.youtube.com/watch?v=LuKehlKoN7o&lc=z22qu35a4xawiriehacdp435fnpjgmq2f54mjmyhi2tw03c010c.1502618893412377), where I
covered the following:

* Discussions about app setup and protocol-driven development
* Using `Alamofire` to fetch data from a restaurant API (Yelp)
* Mapping data with `AlamofireObjectMapper` and `ObjectMapper`
* Persisting the data with `Realm` and use it as a database cache
* Retrying requests with Alamofire´s `RequestRetrier`
* Adapting and decorating requests with Alamofire´s `RequestAdapter`
* Managing dependencies with Dependency Injection and [Dip](https://github.com/AliSoftware/Dip)

In this post, I'll recreate this entire app from scratch, with some modifications.
I will modify the code a lot and to use a fake, static API instead instead of the
Yelp API. Read more on this further down.


# Video

You can [watch the original talk here](https://www.youtube.com/watch?v=LuKehlKoN7o&lc=z22qu35a4xawiriehacdp435fnpjgmq2f54mjmyhi2tw03c010c.1502618893412377). It does
focus more on the concepts than on the code, but maybe that talk and this post is
a good complement to eachother?


# Source Code

I really recommend you to create a blank iOS project and go through all the steps
in this post yourself. However, you can download the complete source code for the
app [from GitHub](https://github.com/danielsaidi/AlamofireRealmDemo).

If you want to run the demo application in the repo, you have to run `pod install`
from the `DemoApplication` folder, then use `DemoApplication.xcworkspace` instead
of `DemoApplication.xcodeproj`. 


# Prerequisites

For this tutorial, you'll need to install [Xcode](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=0ahUKEwi7lP7s--XVAhVmEpoKHcVkBzUQ0EMIKg&url=https%3A%2F%2Fdeveloper.apple.com%2Fxcode%2Fdownloads%2F&usg=AFQjCNFpOFz2CXarfnUzyEM1Lbia_k7fZw).
You also need [CocoaPods](https://cocoapods.org/) to manage external libraries.


# Disclaimer 

In large app projects, I prefer to extract as much code and logic as possible to
separate libraries, which I then use as decoupled building blocks. For instance,
I would keep domain logic in a domain library, which doesn't know anything about
the app. In this small project, however, I will keep the domain model in the app.

I use to separate public and private functions and any interface implementations
into extensions as well, but will skip that pattern in this demo, so that we get
as little code and conventions as possible. 


# Why use a static API?

In this demo, we will use a static API to fetch movies in different ways. The API
is just a static Jekyll site with a small movie collection, that lets us grab top
grossing and top rated movies, as well as single movie objects. You can check out
the api source code in the `gh-pages` branch of the demo repository.

If you want to have a look at the data that is returned from the API, you can use
these links:

* [Get a single movie by id](http://danielsaidi.com/AlamofireRealmDemo/api/movies/1)
* [Get top grossing movies 2016](http://danielsaidi.com/AlamofireRealmDemo/api/movies/topGrossing/2016)
* [Get top grossing movies 2016 - sorted on best rating](http://danielsaidi.com/AlamofireRealmDemo/api/movies/topRated/2016)

This may seem limited, but hopefully lets us focus on Alamofire and Realm and not
on understanding an external API and having to set up a developer account, manage
authorization and authentication etc.

Ready? Let's go!


# Step 1 - Create a new iOS project

We'll start by creating a new iOS project in `Xcode`. Open Xcode, click `Create a
new Xcode project`, select the `iOS` tab, then select a `Single View Application`.

![Image](img/1-create.png)

Press `Next` to select where to create your project. You will then have a new iOS
project just waiting to be filled with amazing code.


# Step 2 - Define the domain model

In this demo, we will fetch movies from a fake API. A `Movie` has some basic info
and a `cast` property that contains `Actor` objects. For simplicity, `Actor` only
has a name and is used to demonstrate recursive mapping.
 
To avoid having an app that is coupled to a specific implementation of the domain
model, let us start by defining this model as protocols. Create a `Domain` folder
in the project root, then add a `Model` sub folder with these two files:

```
// Movie.swift

import Foundation

protocol Movie {
    
    var id: Int { get }
    var name: String { get }
    var year: Int { get }
    var releaseDate: Date { get }
    var grossing: Int { get }
    var rating: Double { get }
    var cast: [Actor] { get }
}
```

```
// Actor.swift

import Foundation

protocol Actor {
    
    var name: String { get }
}
```

As you will see later, our app will only use protocols. Not implementations. This
makes it super easy to switch out the implementations used by the app. Stay tuned.


# Step 3 - Define the domain logic

Since we have a static API with no authorization or authentication, we don't have
to start with setting this up. Instead, we can describe how to fetch movies.

Add a `Services` sub folder to `Domain` and add this file:

```
// MovieService.swift

import Foundation

typealias MovieResult = (_ movie: Movie?, _ error: Error?) -> ()
typealias MoviesResult = (_ movies: [Movie], _ error: Error?) -> ()


protocol MovieService: class {
    
    func getMovie(id: Int, completion: @escaping MovieResult)
    func getTopGrossingMovies(year: Int, completion: @escaping MoviesResult)
    func getTopRatedMovies(year: Int, completion: @escaping MoviesResult)
}

```

It took me a while to start using `typealias`, but I really like it now since it
simplifies describing async results and makes the code more readable.

This service tells us that we will be able to get movies asynchronously. Well, a
completion block implies it, but doesn't enforce async). The result data for the
two array functions will be indentically formatted, while the third function may
return a single object.


# Step 4 - Add Alamofire and AlamofireObjectMapper to the project

Before we can add an API-specific implementation to the project, we must add two
`pods`. Make sure CocoaPods is installed, then run the following in the app root:

```
pod init
```

This will create a `Podfile`, in which you can specify the pods the app requires.
Make sure that the file looks like this:

```
// Podfile

use_frameworks!

target 'DemoApplication' do
    pod 'Alamofire', '~> 4.0.0'
    pod 'AlamofireObjectMapper', '~> 4.0' 
end
``` 

Now, close this file and run the following Terminal command from the same folder:

```
pod install
```

This makes CocoaPods download the pods and link them to your Xcode project. Once
that is done, close the project and open `DemoApplication.xcworkspace`.


# Step 5 - Create an API-specific model

Let's create an API-specific implementation of the domain model. Create an `API`
folder in the project root, then add a `Model` sub folder with these two files:

```
// ApiMovie.swift

import ObjectMapper

class ApiMovie: Movie, Mappable {
    
    required public init?(map: Map) {}
    

    var id = 0
    var name = ""
    var year = 0
    var releaseDate = Date(timeIntervalSince1970: 0)
    var grossing = 0
    var rating = 0.0
    var cast: [Actor] { return _cast }
    
    private var _cast = [ApiActor]()
    
    
    func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        year <- map["year"]
        releaseDate <- (map["releaseDate"], DateTransform.custom)
        grossing <- map["grossing"]
        rating <- map["rating"]
        _cast <- map["cast"]
    }
}
``` 

```
// ApiActor.swift

import ObjectMapper

class ApiActor: Actor, Mappable {
    
    required public init?(map: Map) {}
    

    var name = ""
    

    func mapping(map: Map) {
        name <- map["name"]
    }
}
``` 

The classes implement a protocol each and adds additional mapping. `ApiActor` is
straightforward, while `ApiMovie` can be further described:

* The release date is parsed using a DateTransform() instance. We may have to do
tweak this later on.

* The `Movie` protocol has an [Actor] array, but the mapping requires [ApiActor].
We thus use a private `_cast` mapping property and let `cast` be calculated.

If we have set things up properly, we should now be able to point Alamofire to a
valid api url and recursively parse movie data without any effort.


# Step 6 - Set up the API foundation

Before we create an API-specific `MovieService` implementation, let's setup some
core API logic in the `API` folder.

## Managing API environments

Since we developers often have to switch between different API environments (e.g.
test and production) I use to have an enum where I manage available environments.
We only have one single environment in this case, but let's do it anyway:

```
// ApiEnvironment.swift

import Foundation

enum ApiEnvironment: String { case
    
    production = "http://danielsaidi.com/AlamofireRealmDemo/api/"
    
    var url: String {
        return rawValue
    }
}

```

## Managing API routes

With the environments in place, we can list all available routes in another enum:

```
// ApiRoute.swift

enum ApiRoute { case
    
    movie(id: Int),
    topGrossingMovies(year: Int),
    topRatedMovies(year: Int)
    
    var path: String {
        switch self {
        case .movie(let id): return "movies/\(id)"
        case .topGrossingMovies(let year): return "movies/topGrossing/\(year)"
        case .topRatedMovies(let year): return "movies/topRated/\(year)"
        }
    }
    
    func url(for environment: ApiEnvironment) -> String {
        return "\(environment.url)/\(path)"
    }
}
```

Since `year` and `id` are dynamic route segments, we use parametered enum cases.

## Managing API context

I use to have an API context that holds all API-specific information for the app,
such as environment and auth tokens. If you use a singleton context, all context
based services will automatically be affected when the context is modified.

Let's create an `ApiContext` protocol, as well as a non-persisted implementation,
in a new `Context` sub folder in the `Api` folder:

```
// ApiContext.swift

import Foundation

protocol ApiContext: class {
    
    var environment: ApiEnvironment { get set }
}
```   

```
// NonPersistedApiContext.swift

import Foundation

class NonPersistentApiContext: ApiContext {
    
    init(environment: ApiEnvironment) {
        self.environment = environment
    }
    
    var environment: ApiEnvironment
}
```

We can now inject this context into all out API-specific service implementations,
as you will see later.

## Specifying basic API behavior

To simplify how to talk with the API using Alamofire, let us create a base class
for our API-based services. Add a `Services` sub folder to the `Api` folder then
add this file to it:

```
// AlamofireService.swift

class AlamofireService {    
    
    init(context: ApiContext) {
        self.context = context
    }
    
    
    var context: ApiContext
    
    
    func get(at route: ApiRoute, params: Parameters? = nil) -> DataRequest {
        return request(at: route, method: .get, params: params, encoding: URLEncoding.default)
    }
    
    func post(at route: ApiRoute, params: Parameters? = nil) -> DataRequest {
        return request(at: route, method: .post, params: params, encoding: JSONEncoding.default)
    }
    
    func put(at route: ApiRoute, params: Parameters? = nil) -> DataRequest {
        return request(at: route, method: .put, params: params, encoding: JSONEncoding.default)
    }
    
    func request(at route: ApiRoute, method: HTTPMethod, params: Parameters?, encoding: ParameterEncoding) -> DataRequest {
        let url = route.url(for: context.environment)
        return Alamofire.request(url, method: method, parameters: params, encoding: encoding).validate()
    }
}
``` 

Restricting our services to requests that are specified in `ApiRoute` will ensure
that the app doesn't make any unspecified requests, which increases the stability,
and testability of the app. In you really need to call custom URLs, I suggest you
add a `.custom(...)` case in the `ApiRoute` enum. 

Ok, that was a nice long preparation phase mainly aimed at setting up a good base
for the future. I think we're now ready to fetch some movies from the API.


# Step 7 - Create an API-specific movie service

Now, let's create an API-specific service and fetch some data from our API, shall
we? Add this file to the `Api/Services` folder:

```
import Alamofire
import AlamofireObjectMapper

class AlamofireMovieService: AlamofireService, MovieService {
    
    func getMovie(id: Int, completion: @escaping MovieResult) {
        get(at: .movie(id: id)).responseObject {
            (res: DataResponse<ApiMovie>) in
            completion(res.result.value, res.result.error)
        }
    }
    
    func getTopGrossingMovies(year: Int, completion: @escaping MoviesResult) {
        get(at: .topGrossingMovies(year: year)).responseArray {
            (res: DataResponse<[ApiMovie]>) in
            completion(res.result.value ?? [], res.result.error)
        }
    }
    
    func getTopRatedMovies(year: Int, completion: @escaping MoviesResult) {
        get(at: .topRatedMovies(year: year)).responseArray {
            (res: DataResponse<[ApiMovie]>) in
            completion(res.result.value ?? [], res.result.error)
        }
    }
}
```

As you can see, the implementation is super-simple. Just perform get requests on
the routes and specify the return type. Alamofire and AlamofireObjectMapper will
take care of fetching and mapping the returned data.

`getMovie` uses `responseObject`, while the other functions use `responseArray`.
This is because a single movie is returned as a single object while top grossing
and top rated movies are returned as arrays. If the arrays should be returned in
an embedded object instead (a very common case), you would have to specify a new
API-specific mapping type and use `responseObject`.


# Step 8 - Perform your very first request

We will now setup our app to fetch data from the API. Remove all the boilerplate
code from `AppDelegate` and `ViewController`, then add this to `ViewController`:

```
override func viewDidLoad() {
    super.viewDidLoad()
    let env = ApiEnvironment.production
    let context = NonPersistentApiContext(environment: env)
    let service = AlamofireMovieService(context: context)
    service.getTopGrossingMovies(year: 2016) { (movies, error) in
        if let error = error {
            return print(error.localizedDescription)
        }
        print("Found \(movies.count) movies:")
        movies.forEach { print("   \($0.name)") }
    }
}
```

**IMPORTANT** Before you can test this in your app, you have to allow the app to
perform external API requests. Just add this to `Info.plist` (in a real life app,
though, you should specify the exact domains that the app is allowed to access):

```
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

Run the app. If everything is correctly setup, it should print our the following:

```
Found 10 movies:
   Finding Dory
   Rouge One - A Star Wars Story
   Captain America - Civil War
   The Secret Life of Pets
   The Jungle Book
   Deadpool
   Zootopia
   Batman v Superman - Dawn of Justice
   Suicide Squad
   Doctor Strange
```

If you see this in Xcode's log, our app loads movie data from the API. Well done!

Now change the print format for each movie to look like this:

```
movies.forEach { print("   \($0.name) (\($0.releaseDate))") }
```

The app should not output the following:

```
Found 10 movies:
   Finding Dory (1970-01-01 00:33:36 +0000)
   Rouge One - A Star Wars Story (1970-01-01 00:33:36 +0000)
   Captain America - Civil War (1970-01-01 00:33:36 +0000)
   The Secret Life of Pets (1970-01-01 00:33:36 +0000)
   The Jungle Book (1970-01-01 00:33:36 +0000)
   Deadpool (1970-01-01 00:33:36 +0000)
   Zootopia (1970-01-01 00:33:36 +0000)
   Batman v Superman - Dawn of Justice (1970-01-01 00:33:36 +0000)
   Suicide Squad (1970-01-01 00:33:36 +0000)
   Doctor Strange (1970-01-01 00:33:36 +0000)
```

Oooops! Seems like the date parsing does not work (I TOLD you that we would have
fix this later!). Let's fix it.


# Step 9 - Fix date parsing

The problem is that the API uses a different date format than the `ObjectMapper`
library expects. We can solve this by adding an extension for the `ObjectMapper`
`DateTransform` class. Add this file to `Api/Extensions`:

```
DateTransform_Custom.swift

import ObjectMapper

public extension DateTransform {
    
    public static var custom: DateFormatterTransform {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return DateFormatterTransform(dateFormatter: formatter)
    }
}
```

Now change the `releaseDate` mapping in `ApiMovie` to look like this:

```
releaseDate <- (map["releaseDate"], DateTransform.custom)
```

Run the app once more. The dates should now look a lot better:

```
Found 10 movies:
   Finding Dory (2016-06-17 00:00:00 +0000)
   Rouge One - A Star Wars Story (2016-12-16 00:00:00 +0000)
   Captain America - Civil War (2016-05-06 00:00:00 +0000)
   The Secret Life of Pets (2016-07-08 00:00:00 +0000)
   The Jungle Book (2016-04-15 00:00:00 +0000)
   Deadpool (2016-02-12 00:00:00 +0000)
   Zootopia (2016-03-04 00:00:00 +0000)
   Batman v Superman - Dawn of Justice (2016-03-25 00:00:00 +0000)
   Suicide Squad (2016-08-05 00:00:00 +0000)
   Doctor Strange (2016-11-05 00:00:00 +0000)
```

If you inspect the other properties, you will see that they are correctly parsed.

Time to celebrate! Grab something to drink, go for a walk, rest your eyes...then
return here for the next step: persisting to Realm.


# Step 10 - Add Realm to the project

We will now add Realm to our project. Create a `Realm` folder in the application
root, then add a `Model` and a `Services` folder to it. Now, let's create...wait!

Before we can use Realm, we have to grab it from CocoaPods. Add this to `podfile`:

```
pod 'RealmSwift'
```

To make Realm work, you must also add this to the very end of the `podfile`:

```
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
```

Run `pod install` from the `DemoApplication` folder to add Realm to your project.
We can now create our Realm classes.


# Step 11 - Create a Realm-specific model

Let's create Realm-specific model classes. These classes will either be manually
created as we persist data from the API (since we will save these objects to the
database) or automatically as we fetch data from the database.

Realm will take care of the latter case, but we have to find a way to easily map
API-specific objects to Realm-specific ones. 

Add these two files to the `Realm/Model` folder:

```
// RealmMovie.swift

import RealmSwift

class RealmMovie: Object, Movie {
    
    convenience required public init(copy obj: Movie) {
        self.init()
        id = obj.id
        name = obj.name
        year = obj.year
        releaseDate = obj.releaseDate
        grossing = obj.grossing
        rating = obj.rating
        _cast.append(contentsOf: obj.cast.map { RealmActor(copy: $0) })
    }
    

    dynamic var id = 0
    dynamic var name = ""
    dynamic var year = 0
    dynamic var releaseDate = Date(timeIntervalSince1970: 0)
    dynamic var grossing = 0
    dynamic var rating = 0.0
    var cast: [Actor] { return Array(_cast) }
    
    var _cast = List<RealmActor>()


    override class func primaryKey() -> String? {
        return "id"
    }
}
```

```
// RealmActor.swift

import RealmSwift

class RealmActor: Object, Actor {
    
    convenience required public init(copy obj: Actor) {
        self.init()
        name = obj.name
    }
    

    dynamic var name = ""
    

    override class func primaryKey() -> String? {
        return "name"
    }
}
```

Both classes inherit `Realm`'s `Object` class and have a convenience initializer
that copies properties from another protocol instance.

Like the API model, `RealmActor` is pretty straightforward while the `RealmMovie`
class is more complex. Like `ApiMovie`, it has a private `_cast` property, which
is used as the calculated `cast` property's backing value. This `_cast` property
is a Realm `List<RealmActor>`, while `cast` is an `[Actor]` array, just like the
protocol requires.


# Step 12 - Create a Realm-specific movie service

Now let's add a Realm-specific `MovieService` that lets us store movies from the
API to Realm. Add this file to `Realm/Services`:

```
// RealmMovieService.swift

import RealmSwift

class RealmMovieService: MovieService {
    
    init(baseService: MovieService) {
        self.baseService = baseService
    }
    
    
    fileprivate let baseService: MovieService
    
    fileprivate var realm: Realm { return try! Realm() }
    
    
    func getMovie(id: Int, completion: @escaping MovieResult) {
        getMovieFromDb(id: id, completion: completion)
        getMovieFromService(id: id, completion: completion)
    }
    
    func getTopGrossingMovies(year: Int, completion: @escaping MoviesResult) {
        getTopGrossingMoviesFromDb(year: year, completion: completion)
        getTopGrossingMoviesFromService(year: year, completion: completion)
    }
    
    func getTopRatedMovies(year: Int, completion: @escaping MoviesResult) {
        getTopRatedMoviesFromDb(year: year, completion: completion)
        getTopRatedMoviesFromService(year: year, completion: completion)
    }
    
    
    fileprivate func getMovieFromDb(id: Int, completion: @escaping MovieResult) {
        let obj = realm.object(ofType: RealmMovie.self, forPrimaryKey: id)
        completion(obj, nil)
    }
    
    fileprivate func getMovieFromService(id: Int, completion: @escaping MovieResult) {
        baseService.getMovie(id: id) { (movie, error) in
            self.persist(movie)
            completion(movie, error)
        }
    }
    
    fileprivate func getTopGrossingMoviesFromDb(year: Int, completion: @escaping MoviesResult) {
        let objs = realm.objects(RealmMovie.self).filter("year == \(year)")
        let sorted = objs.sorted { $0.grossing > $1.grossing }
        completion(Array(sorted), nil)
    }
    
    fileprivate func getTopGrossingMoviesFromService(year: Int, completion: @escaping MoviesResult) {
        baseService.getTopGrossingMovies(year: year) {  (movies, error) in
            self.persist(movies)
            completion(movies, error)
        }
    }
    
    fileprivate func getTopRatedMoviesFromDb(year: Int, completion: @escaping MoviesResult) {
        let objs = realm.objects(RealmMovie.self).filter("year == \(year)")
        let sorted = objs.sorted { $0.rating > $1.rating }
        completion(Array(sorted), nil)
    }
    
    fileprivate func getTopRatedMoviesFromService(year: Int, completion: @escaping MoviesResult) {
        baseService.getTopRatedMovies(year: year) {  (movies, error) in
            self.persist(movies)
            completion(movies, error)
        }
    }
    
    fileprivate func persist(_ movie: Movie?) {
        guard let movie = movie else { return }
        persist([movie])
    }
    
    fileprivate func persist(_ movies: [Movie]) {
        let objs = movies.map { RealmMovie(copy: $0) }
        try! realm.write {
            realm.add(objs, update: true)
        }
    }
}
```

As you can see, `RealmMovieService`'s initializer requires another `MovieService`
instance. Why is that?

`RealmMovieService` is a so called `decorator`, which uses a base implementation
of a protocol it implements, to extend the base implementation with its on logic.
In this case, our `baseService` is an `AlamofireMovieService`, but the decorator
shouldn't care about how the base service works, just what the protocol promises.

In this case, `RealmMovieService` will try to get data from the database, but at
the same time, it will also try to get data from the base service. When the base
service completes, `RealmMovieService` saves any data it receives. It then calls
the incoming completion block, to notify its caller about the new data.

`Disclaimer:` This is an intentionally simple design. `RealmMovieService` always
loads data from the database **and** from the base service. In a real app, you'd
probably have some logic to determine if calling the base service is needed.


# Step 13 - Put Realm into action

Let's give whatever we have now a try. Modify `viewDidLoad` to look like this:

```
override func viewDidLoad() {
    super.viewDidLoad()
    let env = ApiEnvironment.production
    let context = NonPersistentApiContext(environment: env)
    let baseService = AlamofireMovieService(context: context)
    let service = RealmMovieService(baseService: baseService)
    var invokeCount = 0
    service.getTopGrossingMovies(year: 2016) { (movies, error) in
        invokeCount += 1
        if let error = error {
            print("ERROR: \(error.localizedDescription)")
        } else {
            print("Found \(movies.count) movies (callback #\(invokeCount))")
        }
    }
}
```

In the code above, we rename the Alamofire service to `baseService`, then create
a Realm service into which we inject `baseService`. The app is still loading top
grossing movies using a `service` instance, but this time the service will first
check the database, then call the API. However, the app does not care about this.
It only cares about the protocol, not how it is implemented.

The output will be the following, the first time we run the app with this setup:

```
Found 0 movies  (callback #1)
Found 10 movies (callback #2)
```

This happens because the database has no data, while the API will load 10 movies.
If you run the app again, the output should be:

```
Found 10 movies (callback #1)
Found 10 movies (callback #2)
```

This happens because the database now has data, which means that both completion
calls will return 10 movies.

Now, go ahead and **KILL THE INTERNET CONNECTION**, then call `getTopRatedMovies`
instead of `getTopGrossingMovies` (Alamofire will cache the previous result). If
you run the app again, the output should be:

```
Found 10 movies (callback #1)
ERROR: The Internet connection appears to be offline.
```

This happens because the database data can still be loaded, while the API cannot
be called since the Internet connection is dead.

We now have an app with offline support, that only refreshes its data whenever a
call to the API provides the app with new data. All we had to do was to change a
single line in the view controller, to use another service implementation.


# Step 14 - Retry failing requests

In the real world, a user most often has to authenticate her/himself in order to
use some parts of an API. Authentication often returns a set of tokens, commonly
an `auth token` and a `refresh token` (but how this works is up to the API).

If the `auth token` and `refresh token` pattern is used, the authentication flow
could look something like this:

* If no auth token is available and the request fails with a 401, the app should
show a login screen, since the user has to login.

* If an auth token is available, the app can try to call the API with that token.

* If an auth token is available, but the requests fail with a 401, the token may
have expired. The app should use the refresh token to request new tokens.

* If the refresh succeeds, the app will have new tokens and should automatically
retry all previously failed requests.

* If the refresh fails, the app should logout the user and show a login screen.

Alamofire 4 makes this kind of logic **super simple** to implement, since it has
a `RequestRetrier` protocol that we can implement and inject into Alamofire. The
retrier will be notified about all failing requests, and lets you determine if a
request should be retried or not, and if so how it should be retried.

We will demonstrate this by faking a failing auth. First, add an `auth` route to
`ApiRoute`, and have it return `auth` as path. Our static API will always return
the same "auth token" when this route is called.

Second, add this file to `Domain/Services`:

```
// AuthService.swift

import Foundation

typealias AuthResult = (_ token: String?, _ error: Error?) -> ()


protocol AuthService: class {

    func authorizeApplication(completion: @escaping AuthResult)
}
``` 

This is a really simple protocol that defines how the app is to authorize itself.
Before we implement it, we have to add a way to store any auth tokens we receive.

`Disclaimer:` As an app grows, I find it easier to separate the app into context
related parts instead of class types. In other words, instead of the `Model` and
`Services` grouping, the app should probably benefit from grouping the code into
`Movies` and `Authentication` groups instead, where each group could contain all
related functionality for that group, like views, extensions etc.

Ok, back to storing auth tokens. Remember what I told you about the `ApiContext`
earlier? Well, it's a **PERFECT** place to store these tokens, so let's do just
that. Add an `authToken` property to the `ApiContext` protocol:

```
var authToken: String? { get set }
```

Also, add the property to `NonPersistentApiContext` (if we had a persistent one,
it would remember the auth token even if restarted the app):

```
var authToken: String?
```

Now, let's add an Alamofire-based `AuthService` implementation to `Api/Services`:


```
// AlamofireAuthService.swift

import Alamofire
import AlamofireObjectMapper

class AlamofireAuthService: AlamofireService, AuthService {
    
    func authorizeApplication(completion: @escaping AuthResult) {
        get(at: .auth).responseString {
            (res: DataResponse<String>) in
            if let token = res.result.value {
                self.context.authToken = token
            }
            completion(res.result.value, res.result.error)
        }
    }
}
``` 

If the API request above succeeds, the token is saved in our context. This will
make it available to all future API requests.

Now, let's retry some requests! Add this file to the `Api` folder:

```
import Alamofire

class ApiRequestRetrier: RequestRetrier {
    
    init(context: ApiContext, authService: AuthService) {
        self.context = context
        self.authService = authService
    }
    
    
    fileprivate let authService: AuthService
    fileprivate let context: ApiContext
    fileprivate var isAuthorizing = false
    fileprivate var retryQueue = [RequestRetryCompletion]()
    
    
    func should(
        _ manager: SessionManager,
        retry request: Request,
        with error: Error,
        completion: @escaping RequestRetryCompletion) {
        
        guard
            shouldRetryRequest(with: request.request?.url),
            shouldRetryResponse(with: request.response?.statusCode)
            else { return completion(false, 0) }
        
        authorize(with: completion)
    }
    
    
    fileprivate func authorize(with completion: @escaping RequestRetryCompletion) {
        print("Authorizing application...")
        retryQueue.append(completion)
        guard !isAuthorizing else { return }
        isAuthorizing = true
        authService.authorizeApplication { (token, error) in
            self.printAuthResult(token, error)
            self.isAuthorizing = false
            self.context.authToken = token
            let success = token != nil
            self.retryQueue.forEach { $0(success, 0) }
            self.retryQueue.removeAll()
        }
    }

    fileprivate func printAuthResult(_ token: String?, _ error: Error?) {
        if let error = error {
            return print("Authorizing failed: \(error.localizedDescription)")
        } 
        if let token = token {
            return print("Authorizing succeded: \(token)")
        } 
        print("No token received - failing!")
    }

    fileprivate func shouldRetryRequest(with url: URL?) -> Bool {
        guard let url = url?.absoluteString else { return false }
        let authPath = ApiRoute.auth.path
        return !url.contains(authPath)
    }
    
    fileprivate func shouldRetryResponse(with statusCode: Int?) -> Bool {
        return true // statusCode == 401
    }
}

```

Whenever a request fails, Alamofire will ask the retrier if it should be retried.
The retrier will trigger a retry if the request is not a failing auth (read more
about the commented out 401 later down). If not, it just lets the request fail.

If a request should be retried, it's added it to a retry queue. The retrier then
triggers an authorization. Once it completes, the retrier checks if it succeeded.
If so, all queued requests are retried. If not, all queued requests fail and the
retry queue is cleared.

Note that this is completely hidden from the user as well as the app itself. The
retrier works under the hood, tightly connected to Alamofire's internal workings.
It just notifies the app if the authorization fails, by failing all requests.

Inject the retrier into `Alamofire` by adding the following to our `viewDidLoad`
(note that you have to add `import Alamofire` topmost as well):

```
let sessionManager = SessionManager.default
sessionManager.retrier = ApiRequestRetrier(context: context, authService: authService)
```

**IMPORTANT**  In the real world, a 401 status code is an indication that tokens
should be refreshed. If this refresh fails, a 401 indicates that the user has to
log in, since the tokens are invalid. Here, however, we will never receive a 401.
We therefore have to trigger these mechanisms by doing the following:

* Kill the Internet connection and perform a clean install, so that the app does
not have any cached data.

* Add a breakpoint to the `authService.authorizeApplication` call in the retrier.

* Run the app. The app should now fail the request and activate this breakpoint.

* Bring the Internet connection back online and resume the app. This should make
the authorization call succeed and have Alamofire successfully retry the request.

That's it! Alamofire should now retry any failing request that are not auth ones.


# Step 15 - Adapt all Alamofire requests

Sometimes, you have to add custom headers to every request you make to an API. A
common scenario is to add `Accept` information, auth tokens etc.

To adapt any Alamofire requests before they are sent, you just have to implement
the `RequestAdapter` protocol and inject it into Alamofire. Add this file to the
`Api` folder:

```
// ApiRequestAdapter.swift

import Alamofire

class ApiRequestAdapter: RequestAdapter {
    
    public init(context: ApiContext) {
        self.context = context
    }
    
    
    fileprivate let context: ApiContext
    
    
    func adapt(_ request: URLRequest) throws -> URLRequest {
        guard let token = context.authToken else { return request }
        var request = request
        request.setValue(token, forHTTPHeaderField: "AUTH_TOKEN")
        return request
    }
}
```

As you can see, this adapter just adds any existing token to the request headers.
Inject it into `Alamofire` by adding the following to our `viewDidLoad`:

```
sessionManager.adapter = ApiRequestAdapter(context: context)
```

That's it! Alamofire should now add the auth token to all requests, if it exists.


# Dependency Injection

Well, I won't do this here, since it just add even more complexity to an already
super-long tutorial. In the demo application, however, I have an `IoC` folder in
which I use a library called [Dip](https://github.com/AliSoftware/Dip) to manage
all dependencies in the app. Check it out if you're interested.


# Final view controller adjustments

When using dependency injection, the view controller's code becomes quite clean:

```
import UIKit
import Alamofire

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData(self)
    }
    
    
    lazy var movieService: MovieService = IoC.resolve()
    
    
    fileprivate var movies = [Movie]()
    
    
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            tableView?.delegate = self
            tableView?.dataSource = self
        }
    }
    
    @IBOutlet weak var dataPicker: UISegmentedControl?
    
    
    @IBAction func reloadData(_ sender: Any) {
        let index = dataPicker?.selectedSegmentIndex ?? 0
        index == 0
            ? movieService.getTopGrossingMovies(year: 2016, completion: moviesCompletion)
            : movieService.getTopRatedMovies(year: 2016, completion: moviesCompletion)
    }
    
    fileprivate func moviesCompletion(_ movies: [Movie], _ error: Error?) {
        if let error = error { fatalError(error.localizedDescription) }
        self.movies = movies
        self.tableView?.reloadData()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let movie = movies[indexPath.row]
        let names = movie.cast.map { $0.name }
        cell.textLabel?.text = "\(movie.name) (\(movie.year))"
        cell.detailTextLabel?.text = names.joined(separator: ", ")
        return cell
    }
}
```

The result looks like this, with a segmented control that is used to change data:

![Image](img/15-app.png)

And...


# That's a wrap!

Well done! You have created an app with abstract protocols, then added Alamofire,
object mapping and Realm to the mix. You have also added request retry and adapt
logic using the `RequestRetrier` and `RequestAdapter` protocols. Wow!

I hope this was helpful. Please let me know what you think, and do not hesistate
to throw any thoughts or ideas you have at me.

All the best

Daniel Saidi

* [@danielsaidi](http://twitter.com/danielsaidi)
* [danielsaidi.com](http://danielsaidi.com)
* [daniel.saidi@gmail.com](mailto:danielsaidi@gmail.com)