# CocoaHeads 2017-04-03 - Alamofire, AlamofireObjectMapper and Realm

This is a step-by-step walkthrough of my talk at CocoaHeads Sthlm, April 3rd 2017,
where I demonstrated how to use `Alamofire 4` and `AlamofireObjectMapper` to pull
and parse data from the Yelp API. I also used `Realm` for persistency and a great
library called `Dip` to seemlessly manage dependencies in the app.

In this post, I'll recreate the app from the presentation from scratch. Since the
Yelp API doesn't allow you to save its data, I will modify the setup slightly, to
use a static API instead. Although this means that we will only fetch static data,
it actually simplifies things and lets us focus on the important parts.



# Video

You can watch the original presentation [here](https://www.youtube.com/watch?v=LuKehlKoN7o&lc=z22qu35a4xawiriehacdp435fnpjgmq2f54mjmyhi2tw03c010c.1502618893412377).
Since the presentation focuses more on concepts than code, it's a nice complement
to this more code-oriented post.



# Source Code

I really recommend you to create a blank iOS project and go through all the steps
in this post yourself. However, you can download the complete source code for the
app from [this GitHub repository](https://github.com/danielsaidi/CocoaHeads-2017-04-03-Alamofire-Realm).

If you want to run the demo application, you have to download the source code and
then run `pod install` from the `DemoApplication` folder. After that is done, you
must open `DemoApplication.xcworkspace` instead of `DemoApplication.xcodeproj` if
you want to be able to build the project. 



# Prerequisites

For this tutorial, you'll need to grab [Xcode](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=0ahUKEwi7lP7s--XVAhVmEpoKHcVkBzUQ0EMIKg&url=https%3A%2F%2Fdeveloper.apple.com%2Fxcode%2Fdownloads%2F&usg=AFQjCNFpOFz2CXarfnUzyEM1Lbia_k7fZw)
from Apple Developer Portal. You also need to [CocoaPods](https://cocoapods.org/),
which is used to manage external dependencies in your app.



# Disclaimer

In this demo, we will use a fake/static API to authorize the app and fetch movies
in different ways. Since the fake API has no built-in logic, I will have to force
my way around some limitations, such as how authorization is triggered. I will do
my best to describe these cases and hope that you can look past it and understand
how to modify it to a real-world scenario later on.

In large app projects, I prefer to extract as much code and logic as possible to
separate libraries, which I then use as decoupled building blocks. For instance,
I would keep domain logic in a Domain library, which doesn't know anything about
the app. In this small project, however, I will keep the domain model in the app.



# Step 1 - Create a new iOS project

We'll start by creating a new iOS project in `Xcode`. Open Xcode, click `Create a
new Xcode project`, select the `iOS` tab, then select a `Single View Application`.
In this tutorial, I'll name the project `DemoApplication`:

![Image](img/1-create.png)

Press `Next` to select where to create your project. You will then have a new iOS
project just waiting to be filled with amazing code.



# Step 2 - Describe the domain model

In this demo, we will fetch movies from a fake API. A `Movie` has some basic info
and a `cast` property that contains `Actor` objects. For simplicity, `Actor` only
has a name and is used to demonstrate recursive mapping.
 
To avoid having an app that is coupled to a specific implementation of this model,
let us start by defining this model as protocols. Create a `Domain` folder in the
project root with a `Model` folder with two files: `Movie.swift` and `Actor.swift`.

```
// Movie.swift

import Foundation

protocol Movie {
    
    var name: String { get }
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

As you will see later on, our app will only care about protocols and not specific
implementations. This will make it super easy for us to provide if with different
kind of implementations, such as an API or database object. Stay tuned.



# Step 3 - Describe the domain logic

In this demo, we will use a fake, static API for app authorization and to search
for movies in different ways. Since the static API has no built-in logic, I will
have to adjust the implementation a bit compared to when consuming a dynamic API,
but I hope that you can extend the demo code to real world scenarios later on.

Let us begin with describing how we want the app to fetch movie information. Add
a `Services` folder to `Domain`, then create a `MovieService.swift` file in it.

```
// MovieService.swift

import Foundation

typealias MoviesResult = (_ movies: [Movie], _ error: Error?) -> ()


protocol MovieService: class {
    
    func getBestRatedMovies(year: Int, completion: @escaping MoviesResult)
    func getTopGrossingMovies(year: Int, completion: @escaping MoviesResult)
}

```


# Step 4 - Add Alamofire and AlamofireObjectMapper to the project

Before we can add an API-specific implementation to the project, we must add two
so called `pods` to the project. Make sure CocoaPods is properly installed, then
run the following command from the `DemoApplication` folder:

```
pod init
```

This will setup a `pod file`, in which you can set which pods your app requires.
For now, make sure that the pod file looks like this:

```
use_frameworks!

target 'DemoApplication' do
    pod 'Alamofire', '~> 4.0.0'
    pod 'AlamofireObjectMapper', '~> 4.0' 
end
``` 

Now `close the app project`, then run this Terminal command from the same folder:

```
pod install
```

This will make CocoaPods download some pods and link them with the Xcode project,
then create an Xcode workspace that you have to use from now on. If you can open
and run `DemoApplication.xcworkspace` without compile errors, you are good to go.



# Step 5 - Create an API-specific domain model implementation

We are now ready to use Alamofire to pull some data from the API. Have a look at
the data collections that can be fetched from the API:

* [Top 5 Rated Movies 2015](http://danielsaidi.com/CocoaHeads-2017-04-03-Alamofire-Realm/api/movies/2015/rating)
* [Top 5 Rated Movies 2016](http://danielsaidi.com/CocoaHeads-2017-04-03-Alamofire-Realm/api/movies/2016/rating)
* [Top 5 Grossing Movies 2016](http://danielsaidi.com/CocoaHeads-2017-04-03-Alamofire-Realm/api/movies/2015/grossing)
* [Top 5 Grossing Movies 2016](http://danielsaidi.com/CocoaHeads-2017-04-03-Alamofire-Realm/api/movies/2016/grossing)

As you can see, the "api" provides a very limit set of information, but it works
great to demonstrate how to fetch and parse it with Alamofire.

Let's create an API-specific implementation of the domain model! Create an `API`
folder in the project root. Just as with `Domain`, create a `Model` folder with
two files: `ApiMovie.swift` and `ApiActor.swift`.

```
// ApiMovie.swift

import ObjectMapper

class ApiMovie: NSObject, Movie {
    
    required public init?(map: Map) {
        super.init()
    }
    
    var name = ""
    var releaseDate = Date(timeIntervalSince1970: 0)
    var grossing = 0
    var rating = 0.0
    fileprivate var _cast = [ApiActor]()
    var cast = [Actor]()
}


extension ApiMovie: Mappable {
    
    func mapping(map: Map) {
        
        name <- map["name"]
        releaseDate <- (map["releaseDate"], DateTransform())
        grossing <- map["grossing"]
        rating <- map["grossing"]
        _cast <- map["cast"]
        cast = _cast
    }
}
``` 

```
// ApiActor.swift

import ObjectMapper

class ApiActor: NSObject, Actor {
    
    required public init?(map: Map) {
        super.init()
    }
    
    var name = ""
}


extension ApiActor: Mappable {
    
    func mapping(map: Map) {
        
        name <- map["name"]
    }
}
``` 

As you can see, these classes implement their respecive model protocol, then add
Alamofire mapping ontop. While `ApiActor` is straightforward, some things can be
said about `ApiMovie`:

* The release date is parsed using a DateTransform()
* The `Movie` protocol has an [Actor] array, but the mapping requires [ApiActor].
We therefore use a fileprivate `_cast` property to map cast data then copies the
mapped data to the public `cast` property.

If we have set things up properly, we should now be able to point Alamofire to a
certain api url, and then recursively parse the data without any further effort.



# Step 6 - Create an API-specific domain service implementation

Before we implement an API-specific `MovieService` implementation, let's setup a
base layer for working with Alamofire.

Since real-world APIs can most often run in several different environments, like
test, staging and prod, I prefer to have an enum in the `Api` folder, that lists
all available environments. We only have a "production" environment for our fake
API, but let's go ahead and add this enum nevertheless:

## Managing environments and routes

```
// ApiEnvironment.swift

import Foundation

enum ApiEnvironment: String { case
    
    prod = "http://danielsaidi.com/CocoaHeads-2017-04-03-Alamofire-Realm/api/"
}

extension ApiEnvironment {
    
    var url: String {
        return rawValue
    }
}

```

With this enum in place, we can then list all (static) available API routes in a
separate enum as well:

```
// ApiRoute.swift

enum ApiRoute { case
    
    auth,
    topGrossingMovies(year: Int),
    topRatedMovies(year: Int)
}


extension ApiRoute {
    
    var path: String {
        switch self {
        case .topGrossingMovies(let year): return "movies/\(year)/grossing"
        case .topRatedMovies(let year): return "movies/\(year)/rating"
        }
    }
}


extension ApiRoute {
    
    func url(for environment: ApiEnvironment) -> String {
        return "\(environment.url)/\(path)"
    }
}
```

Since `year` is a dynamic part of the API movie paths, we add a year argument to
the movie routes as well, to ensure that one have to specify the year when using
this enum cases.

## Managing API contexts

To simplify switching API environments without having to create new instances of
the various services, I use to create an `ApiContext` protocol that contains all
the information needed to talk with the API, such as `environment`, `tokens` etc.
If you then use a single instance (singleton) of the context in an app, changing
any information in this singleton would affect all services that use the context
automatically. 

Fow now, let's create an `ApiContext` protocol as well as a simple non-persisted
implementation. We could then create a persisted implementation to the app later
and easily switch it out to make the app remember any changes we made.

However, for now, add these two files to a `Context` folder in the `Api` folder:

   