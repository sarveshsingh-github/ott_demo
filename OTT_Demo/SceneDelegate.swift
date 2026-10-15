//
//  SceneDelegate.swift
//  OTT_Demo
//
//  Created by Sarvesh Singh on 14/10/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // MARK: - Composition Root
        // 1. Data Layer: Instantiate Data Source & Repository
        let dataSource = MockContentRemoteDataSource()
        let repository = ContentRepository(remoteDataSource: dataSource)

        // 2. Domain Layer: Inject Repository into Use Case
        let useCase = GetHomeContentUseCase(repository: repository)

        // 3. Presentation Layer: Inject Use Case into ViewModel
        let homeViewModel = HomeViewModel(getHomeContentUseCase: useCase)

        // 4. UI: Instantiate from separate Home.storyboard & Inject ViewModel
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        guard let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {
            fatalError("Could not instantiate HomeViewController from Home.storyboard")
        }
        homeVC.configure(viewModel: homeViewModel)
        let navigationController = UINavigationController(rootViewController: homeVC)

        // 5. Setup Window
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

