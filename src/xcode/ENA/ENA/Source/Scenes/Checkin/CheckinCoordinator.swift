////
// 🦠 Corona-Warn-App
//

import UIKit
import OpenCombine

final class CheckinCoordinator {
	
	// MARK: - Init
	init(
		store: Store,
		eventStore: EventStoringProviding,
		appConfiguration: AppConfigurationProviding,
		eventCheckoutService: EventCheckoutService
	) {
		self.store = store
		self.eventStore = eventStore
		self.appConfiguration = appConfiguration
		self.eventCheckoutService = eventCheckoutService
		
		#if DEBUG
		if isUITesting {
			// app launch argument
			if let checkinInfoScreenShown = UserDefaults.standard.string(forKey: "checkinInfoScreenShown") {
				store.checkinInfoScreenShown = (checkinInfoScreenShown != "NO")
			}
		}
		#endif
		
		setupCheckinBadgeCount()
	}
	
	// MARK: - Internal
	lazy var viewController: UINavigationController = {
		let checkinsOverviewViewController = CheckinsOverviewViewController(
			viewModel: checkinsOverviewViewModel,
			onInfoButtonTap: { [weak self] in
				self?.presentInfoScreen()
			},
			onAddEntryCellTap: { [weak self] in
				self?.showQRCodeScanner()
			},
			onMissingPermissionsButtonTap: { [weak self] in
				self?.showSettings()
			}
		)
		
		let footerViewController = FooterViewController(
			FooterViewModel(
				primaryButtonName: AppStrings.Checkins.Overview.deleteAllButtonTitle,
				isSecondaryButtonEnabled: false,
				isPrimaryButtonHidden: true,
				isSecondaryButtonHidden: true,
				primaryButtonColor: .systemRed
			)
		)
		
		let topBottomContainerViewController = TopBottomContainerViewController(
			topController: checkinsOverviewViewController,
			bottomController: footerViewController
		)
		
		// show the info screen only once
		if !infoScreenShown {
			return UINavigationController(rootViewController: infoScreen(hidesCloseButton: true, dismissAction: { [weak self] in
				guard let self = self else { return }
				// Push Checkin Table View Controller
				self.viewController.pushViewController(topBottomContainerViewController, animated: true)
				// Set as the only controller on the navigation stack to avoid back gesture etc.
				self.viewController.setViewControllers([topBottomContainerViewController], animated: false)
				self.infoScreenShown = true // remember and don't show it again
			},
			showDetail: { detailViewController in
				self.viewController.pushViewController(detailViewController, animated: true)
			}))
		} else {
			let navigationController = UINavigationController(rootViewController: topBottomContainerViewController)
			navigationController.navigationBar.prefersLargeTitles = true
			return navigationController
		}
	}()
	
	func showQRCodeScanner() {
		
		let qrCodeScanner = CheckinQRCodeScannerViewController(
			qrCodeVerificationHelper: verificationService,
			appConfiguration: appConfiguration,
			didScanCheckin: { [weak self] traceLocation in
				self?.viewController.dismiss(animated: true, completion: {
					self?.showTraceLocationDetails(traceLocation)
				})
			},
			dismiss: { [weak self] in
				self?.checkinsOverviewViewModel.updateForCameraPermission()
				self?.viewController.dismiss(animated: true)
			}
		)
		qrCodeScanner.definesPresentationContext = true
		DispatchQueue.main.async { [weak self] in
			let navigationController = UINavigationController(rootViewController: qrCodeScanner)
			navigationController.modalPresentationStyle = .fullScreen
			self?.viewController.present(navigationController, animated: true)
		}
	}
	
	func showTraceLocationDetailsFromExternalCamera(_ qrCodeString: String) {
		verificationService.verifyQrCode(
			qrCodeString: qrCodeString,
			appConfigurationProvider: appConfiguration,
			onSuccess: { [weak self] traceLocation in
				self?.showTraceLocationDetails(traceLocation)
				self?.verificationService.subscriptions.removeAll()
			},
			onError: { [weak self] error in
				let alert = UIAlertController(
					title: AppStrings.Checkins.QRScanner.Error.title,
					message: error.errorDescription,
					preferredStyle: .alert
				)
				alert.addAction(
					UIAlertAction(
						title: AppStrings.Common.alertActionOk,
						style: .default,
						handler: { _ in
							alert.dismiss(animated: true, completion: nil)
						}
					)
				)
				self?.viewController.present(alert, animated: true)
				self?.verificationService.subscriptions.removeAll()
			}
		)
	}
	
	// MARK: - Private

	private let store: Store
	private let eventStore: EventStoringProviding
	private let appConfiguration: AppConfigurationProviding
	private let eventCheckoutService: EventCheckoutService
	private var subscriptions: [AnyCancellable] = []
	private let verificationService = QRCodeVerificationHelper()

	private var infoScreenShown: Bool {
		get { store.checkinInfoScreenShown }
		set { store.checkinInfoScreenShown = newValue }
	}
	
	private lazy var checkinsOverviewViewModel: CheckinsOverviewViewModel = {
		CheckinsOverviewViewModel(
			store: eventStore,
			eventCheckoutService: eventCheckoutService,
			onEntryCellTap: { [weak self] checkin in
				guard checkin.checkinCompleted else {
					Log.debug("Editing uncompleted checkin is not allowed", log: .default)
					return
				}
				self?.showEditCheckIn(checkin)
			}
		)
	}()

	private func showEditCheckIn(_ checkIn: Checkin) {
		let footerViewController = FooterViewController(
			FooterViewModel(
				primaryButtonName: AppStrings.Checkins.Edit.primaryButtonTitle,
				secondaryButtonName: nil,
				isPrimaryButtonEnabled: true,
				isSecondaryButtonEnabled: false,
				isPrimaryButtonHidden: false,
				isSecondaryButtonHidden: true,
				backgroundColor: .enaColor(for: .cellBackground)
			)
		)

		let editCheckInViewController = EditCheckinDetailViewController(
			eventStore: eventStore,
			checkIn: checkIn,
			dismiss: { [weak self] in
				self?.viewController.dismiss(animated: true)
			}
		)

		let topBottomContainerViewController = TopBottomContainerViewController(
			topController: editCheckInViewController,
			bottomController: footerViewController
		)
		viewController.present(topBottomContainerViewController, animated: true)
	}
	
	private func showTraceLocationDetails(_ traceLocation: TraceLocation) {
		let viewModel = TraceLocationDetailViewModel(traceLocation, eventStore: self.eventStore, store: self.store)
		let traceLocationDetailViewController = TraceLocationDetailViewController(
			viewModel,
			dismiss: { [weak self] in
				self?.viewController.dismiss(animated: true)
			}
		)
		self.viewController.present(traceLocationDetailViewController, animated: true)
	}

	
	private func showSettings() {
		guard let url = URL(string: UIApplication.openSettingsURLString),
			  UIApplication.shared.canOpenURL(url) else {
			Log.debug("Failed to oper settings app", log: .checkin)
			return
		}
		UIApplication.shared.open(url, options: [:])
	}
	
	private func infoScreen(
		hidesCloseButton: Bool = false,
		dismissAction: @escaping (() -> Void),
		showDetail: @escaping ((UIViewController) -> Void)
	) -> UIViewController {
		
		let checkinsInfoScreenViewController = CheckinsInfoScreenViewController(
			viewModel: CheckInsInfoScreenViewModel(
				presentDisclaimer: {
					let detailViewController = HTMLViewController(model: AppInformationModel.privacyModel)
					detailViewController.title = AppStrings.AppInformation.privacyTitle
					detailViewController.isDismissable = false
					if #available(iOS 13.0, *) {
						detailViewController.isModalInPresentation = true
					}
					showDetail(detailViewController)
				},
				hidesCloseButton: hidesCloseButton
			),
			onDismiss: {
				dismissAction()
			}
		)
		
		let footerViewController = FooterViewController(
			FooterViewModel(
				primaryButtonName: AppStrings.Checkins.Information.primaryButtonTitle,
				primaryIdentifier: AccessibilityIdentifiers.Checkin.Information.primaryButton,
				isSecondaryButtonEnabled: false,
				isPrimaryButtonHidden: false,
				isSecondaryButtonHidden: true
			)
		)
		
		let topBottomContainerViewController = TopBottomContainerViewController(
			topController: checkinsInfoScreenViewController,
			bottomController: footerViewController
		)
		
		return topBottomContainerViewController
	}
	
	private func presentInfoScreen() {
		// Promise the navigation view controller will be available,
		// this is needed to resolve an inset issue with large titles
		var navigationController: UINavigationController!
		let infoVC = infoScreen(
			dismissAction: {
				navigationController.dismiss(animated: true)
			},
			showDetail: { detailViewController in
				navigationController.pushViewController(detailViewController, animated: true)
			}
		)
		// We need to use UINavigationController(rootViewController: UIViewController) here,
		// otherwise the inset of the navigation title is wrong
		navigationController = UINavigationController(rootViewController: infoVC)
		viewController.present(navigationController, animated: true)
	}
	
	private func setupCheckinBadgeCount() {
		eventStore.checkinsPublisher
			.receive(on: DispatchQueue.main.ocombine)
			.sink { [weak self] checkins in
				let activeCheckinCount = checkins.filter { !$0.checkinCompleted }.count
				self?.viewController.tabBarItem.badgeValue = activeCheckinCount > 0 ? String(activeCheckinCount) : nil
			}
			.store(in: &subscriptions)
	}
}
