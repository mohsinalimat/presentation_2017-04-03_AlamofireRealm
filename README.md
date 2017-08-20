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
    var averageRating: Double { get }
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
    
    func getBestRatedMovies(completion: @escaping MoviesResult)
    func getTopGrossingMovies(completion: @escaping MoviesResult)
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



# Step 5 - Create an API-specific comain implementation

We are now ready to use Alamofire to pull some data from the API. You can have a
look at the data that is returned from the API by checking out these two links:















repo contains an adjusted version of the Alamofire, AlamofireObjectMapper and Realm presentation I did at CocoaHeads Stockholm 2017-04-03
