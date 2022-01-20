# WSL Competitor WatchOS App #

## Overview ##

The WSL Competitor app is a stand-alone WatchOS app targeted at WSL athletes active competing in a WSL app. The app provides a simple menu system for selecting WSL Tour followed by event (from a list of only active events) and then athlete (again, from a list of only competing or soon to be competing athletes). Once an athlete is selected, the Companion screen launches and displays the following information:

* Current time left in the active heat
* The priority of all athletes competing in the heat
* The top 2 waves scores of the athlete selected from the menu
* Detail on what score the athlete selected needs to advance or win the heat
* The HP pulsing indicator appears when there are concurrent heats, and the athlete has the priority
* A modal screen appears when the athlete is disqualified or interfering others
* A modal screen is shown when event has not started or is paused

The basic app was put together by SlyTrunk for WSL and then Onica took over development in Nov 2019. 

## Getting started ##

The app uses [Cocoapods](https://cocoapods.org) to manage dependencies. Before getting started, make sure you have Cocoapods installed and then, from the root directory, run: 

    pod install
    
Then open WSLAppleWatch.xcworkspace in Xcode.    

## High-Level Details ##

The app is written in Swift 5, targeting WatchOS 6, and uses Storyboards and UIKit. InterfaceControllers are managed using the [MVVM](https://en.wikipedia.org/wiki/Model–view–viewmodel) pattern with binding handled by [RxSwift](https://github.com/ReactiveX/RxSwift).  

Logging is managed using [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack).

An earlier version of the app displayed athlete images, but the feature has since been removed. Therefore [Nuke](https://github.com/kean/Nuke) could likely be removed as a dependency.

## Project Structure ##

* WSLAppleWatch Watchkit App
    * App Assets
    * App Story Board
* WSLAppleWatch WatchKit Extension
    * data - High-Level Swift models used throughout the app. Uses [Himotoki](https://github.com/ikesyo/Himotoki) for JSON marshalling.
    * services - Services classes for interacting with backend HTTP. Built on top of [Alamofire](https://github.com/Alamofire/Alamofire) and leveraging the [RxAlamoFire](https://github.com/RxSwiftCommunity/RxAlamofire) wrapper.
    * ui - InterfaceController and ViewModel classes. 
    * utility - Constants, [Dependency Injection](https://github.com/Swinject/Swinject), and Extensions 
    * view - Other view related classes 

## Backend Services

The app communicates with the following backend services:

* [WSL API](http://api.worldsurfleague.com/) - Official API of WSL
* [WSL Push Service](https://github.com/worldsurfleague/wsl-push-service) - Includes HTTP, WSS, and push notifications. 
    * Note: The app currently points to a deployment in an AWS account (# 362348548487) owned by WSL
    
## Privacy Permission
* Location - while using
* Health Share Usage
* Health Update Usage
    


