//
// 🦠 Corona-Warn-App
//

import XCTest
@testable import ENA

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class ExposureSubmissionTestResultViewModelTests: XCTestCase {
	
	private var store: Store!
	
	override func setUpWithError() throws {
		store = MockTestStore()
	}
	
	func testDidTapPrimaryButtonOnPositiveTestResult() {
		let getTestResultExpectation = expectation(description: "getTestResult on client is called")
		getTestResultExpectation.isInverted = true

		let client = ClientMock()
		client.onGetTestResult = { _, _, _ in
			getTestResultExpectation.fulfill()
		}
		
		let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithSymptomsFlowButtonTap closure is called"
		)

		let coronaTestService = CoronaTestService(client: client, store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .positive, isSubmissionConsentGiven: true)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: {
				onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
			},
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		model.didTapPrimaryButton()
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		waitForExpectations(timeout: .short)
	}
	
	func testDidTapPrimaryButtonOnNegativeInvalidOrExpiredTestResult() {
		let testResults: [TestResult] = [.negative, .invalid, .expired]
		for testResult in testResults {
			let getTestResultExpectation = expectation(description: "getTestResult on client is called")
			getTestResultExpectation.isInverted = true

			let client = ClientMock()
			client.onGetTestResult = { _, _, _ in
				getTestResultExpectation.fulfill()
			}
			
			let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
				description: "onContinueWithSymptomsFlowButtonTap closure is called"
			)
			onContinueWithSymptomsFlowButtonTapExpectation.isInverted = true

			let coronaTestService = CoronaTestService(client: client, store: MockTestStore())
			coronaTestService.pcrTest = PCRTest.mock(testResult: testResult)

			let model = ExposureSubmissionTestResultViewModel(
				coronaTestType: .pcr,
				coronaTestService: coronaTestService,
				onSubmissionConsentCellTap: { _ in },
				onContinueWithSymptomsFlowButtonTap: {
					onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
				},
				onContinueWarnOthersButtonTap: { _ in },
				onChangeToPositiveTestResult: { },
				onTestDeleted: { }
			)
			
			XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
			
			model.didTapPrimaryButton()
			
			XCTAssertTrue(model.shouldShowDeletionConfirmationAlert)
			
			waitForExpectations(timeout: .short)
		}
	}
	
	func testDidTapPrimaryButtonOnPendingTestResult() {
		let getTestResultExpectation = expectation(description: "getTestResult on client is called")

		let client = ClientMock()
		client.onGetTestResult = { _, _, _ in
			getTestResultExpectation.fulfill()
		}
		
		let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithSymptomsFlowButtonTap closure is called"
		)
		onContinueWithSymptomsFlowButtonTapExpectation.isInverted = true

		let coronaTestService = CoronaTestService(client: client, store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(registrationToken: "asdf", testResult: .pending)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: {
				onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
			},
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		model.didTapPrimaryButton()
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		waitForExpectations(timeout: .short)
	}
	
	func testDidTapPrimaryButtonOnPendingTestResultUpdatesButtons() {
		let getTestResultExpectation = expectation(description: "getTestResult on client is called")

		let client = ClientMock()
		client.onGetTestResult = { _, _, completion in
			completion(.success(TestResult.negative.rawValue))
			getTestResultExpectation.fulfill()
		}

		let coronaTestService = CoronaTestService(client: client, store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(registrationToken: "asdf", testResult: .pending)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		do {
			let modelBefore = try XCTUnwrap(model.footerViewModel)
			
			XCTAssertFalse(modelBefore.isPrimaryLoading)
			XCTAssertTrue(modelBefore.isPrimaryButtonEnabled)
			XCTAssertFalse(modelBefore.isPrimaryButtonHidden)
			
			XCTAssertFalse(modelBefore.isSecondaryLoading)
			XCTAssertTrue(modelBefore.isSecondaryButtonEnabled)
			XCTAssertFalse(modelBefore.isSecondaryButtonHidden)
			
			model.didTapPrimaryButton()
			
			waitForExpectations(timeout: .short)
			
			let modelAfter = try XCTUnwrap(model.footerViewModel)
			
			XCTAssertFalse(modelAfter.isPrimaryLoading)
			XCTAssertTrue(modelAfter.isPrimaryButtonEnabled)
			XCTAssertFalse(modelAfter.isPrimaryButtonHidden)
			
			XCTAssertFalse(modelAfter.isSecondaryLoading)
			XCTAssertTrue(modelAfter.isSecondaryButtonEnabled)
			XCTAssertTrue(modelAfter.isSecondaryButtonHidden)
			
		} catch {
			
			XCTFail(error.localizedDescription)
		}
	}
	
	func testDidTapPrimaryButtonOnPendingTestResultSetsError() {
		let getTestResultExpectation = expectation(description: "getTestResult on client is called")

		let client = ClientMock()
		client.onGetTestResult = { _, _, completion in
			completion(.failure(.invalidResponse))
			getTestResultExpectation.fulfill()
		}

		let coronaTestService = CoronaTestService(client: client, store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(registrationToken: "asdf", testResult: .pending)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		model.didTapPrimaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertEqual(model.error, .responseFailure(.invalidResponse))
	}
	
	func testDidTapPrimaryButtonOnPendingTestResultUpdatesButtonsLoadingState() {
		let getTestResultExpectation = expectation(description: "getTestResult on client is called")
		getTestResultExpectation.isInverted = true

		let client = ClientMock()

		let coronaTestService = CoronaTestService(client: client, store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .pending)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)

		client.onGetTestResult = { _, _, completion in
			do {
				let footerViewModel = try XCTUnwrap(model.footerViewModel)

				// Buttons should be in loading state when getTestResult is called on the exposure submission service
				XCTAssertFalse(footerViewModel.isPrimaryButtonEnabled)
				XCTAssertTrue(footerViewModel.isPrimaryLoading)
				XCTAssertFalse(footerViewModel.isSecondaryButtonEnabled)
			} catch {
				XCTFail(error.localizedDescription)
			}

			completion(.success(TestResult.pending.rawValue))

			getTestResultExpectation.fulfill()
		}
		
		model.didTapPrimaryButton()
		
		waitForExpectations(timeout: .short)
		
		do {
			let footerViewModel = try XCTUnwrap(model.footerViewModel)
			
			XCTAssertTrue(footerViewModel.isPrimaryButtonEnabled)
			XCTAssertFalse(footerViewModel.isPrimaryLoading)
			XCTAssertTrue(footerViewModel.isSecondaryButtonEnabled)
			
		} catch {
			
			XCTFail(error.localizedDescription)
		}
	}
		
	func testDidTapSecondaryButtonOnPendingTestResult() {
		let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .pending)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		XCTAssertFalse(model.shouldAttemptToDismiss)
		
		model.didTapSecondaryButton()
		
		XCTAssertTrue(model.shouldShowDeletionConfirmationAlert)
		XCTAssertFalse(model.shouldAttemptToDismiss)
	}
	
	func testDidTapSecondaryButtonOnNegativeInvalidOrExpiredTestResult() {
		let testResults: [TestResult] = [.negative, .invalid, .expired]
		for testResult in testResults {
			let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
			coronaTestService.pcrTest = PCRTest.mock(testResult: testResult)

			let model = ExposureSubmissionTestResultViewModel(
				coronaTestType: .pcr,
				coronaTestService: coronaTestService,
				onSubmissionConsentCellTap: { _ in },
				onContinueWithSymptomsFlowButtonTap: { },
				onContinueWarnOthersButtonTap: { _ in },
				onChangeToPositiveTestResult: { },
				onTestDeleted: { }
			)
			
			XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
			XCTAssertFalse(model.shouldAttemptToDismiss)
			
			model.didTapSecondaryButton()
			
			XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
			XCTAssertFalse(model.shouldAttemptToDismiss)
		}
	}
	
	func testDeletion() {
		let onTestDeletedCalledExpectation = expectation(description: "onTestDeleted closure is called")

		let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .expired)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: {
				onTestDeletedCalledExpectation.fulfill()
			}
		)
		
		model.deleteTest()
		
		waitForExpectations(timeout: .short)

		XCTAssertNil(coronaTestService.pcrTest)
	}
	
	func testNavigationFooterItemForPendingTestResult() {
		do {
			let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
			coronaTestService.pcrTest = PCRTest.mock(testResult: .pending)

			let model = ExposureSubmissionTestResultViewModel(
				coronaTestType: .pcr,
				coronaTestService: coronaTestService,
				onSubmissionConsentCellTap: { _ in },
				onContinueWithSymptomsFlowButtonTap: { },
				onContinueWarnOthersButtonTap: { _ in },
				onChangeToPositiveTestResult: { },
				onTestDeleted: { }
			)
			
			let footerViewModel = try XCTUnwrap(model.footerViewModel)
			
			XCTAssertFalse(footerViewModel.isPrimaryLoading)
			XCTAssertTrue(footerViewModel.isPrimaryButtonEnabled)
			XCTAssertFalse(footerViewModel.isPrimaryButtonHidden)
			
			XCTAssertFalse(footerViewModel.isSecondaryLoading)
			XCTAssertTrue(footerViewModel.isSecondaryButtonEnabled)
			XCTAssertFalse(footerViewModel.isSecondaryButtonHidden)
			
		} catch {
			
			XCTFail(error.localizedDescription)
		}
	}
	
	func testNavigationFooterItemForPositiveTestResult() {
		
		do {
			let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
			coronaTestService.pcrTest = PCRTest.mock(testResult: .positive)

			let model = ExposureSubmissionTestResultViewModel(
				coronaTestType: .pcr,
				coronaTestService: coronaTestService,
				onSubmissionConsentCellTap: { _ in },
				onContinueWithSymptomsFlowButtonTap: { },
				onContinueWarnOthersButtonTap: { _ in },
				onChangeToPositiveTestResult: { },
				onTestDeleted: { }
			)
			
			let footerViewModel = try XCTUnwrap(model.footerViewModel)
			
			XCTAssertFalse(footerViewModel.isPrimaryLoading)
			XCTAssertTrue(footerViewModel.isPrimaryButtonEnabled)
			XCTAssertFalse(footerViewModel.isPrimaryButtonHidden)
			
			XCTAssertFalse(footerViewModel.isSecondaryLoading)
			XCTAssertTrue(footerViewModel.isSecondaryButtonEnabled)
			XCTAssertFalse(footerViewModel.isSecondaryButtonHidden)
			
		} catch {
			
			XCTFail(error.localizedDescription)
		}
	}
	
	func testNavigationFooterItemForNegaitveInvalidOrExpiredTestResult() {
		do {
			let testResults: [TestResult] = [.negative, .invalid, .expired]
			for testResult in testResults {
				let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
				coronaTestService.pcrTest = PCRTest.mock(testResult: testResult)

				let model = ExposureSubmissionTestResultViewModel(
					coronaTestType: .pcr,
					coronaTestService: coronaTestService,
					onSubmissionConsentCellTap: { _ in },
					onContinueWithSymptomsFlowButtonTap: { },
					onContinueWarnOthersButtonTap: { _ in },
					onChangeToPositiveTestResult: { },
					onTestDeleted: { }
				)
				
				let footerViewModel = try XCTUnwrap(model.footerViewModel)
				
				XCTAssertFalse(footerViewModel.isPrimaryLoading)
				XCTAssertTrue(footerViewModel.isPrimaryButtonEnabled)
				XCTAssertFalse(footerViewModel.isPrimaryButtonHidden)
				
				XCTAssertFalse(footerViewModel.isSecondaryLoading)
				XCTAssertFalse(footerViewModel.isSecondaryButtonEnabled)
				XCTAssertTrue(footerViewModel.isSecondaryButtonHidden)
			}
			
		} catch {
			
			XCTFail(error.localizedDescription)
		}
		
	}
	
	func testDynamicTableViewModelForPositiveTestResult() {
		let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .positive)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 4)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fourthItem = cells[3]
		id = fourthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
	}
	
	func testDynamicTableViewModelForNegativeTestResult() {
		let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .negative)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 9)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fourthItem = cells[3]
		id = fourthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fifthItem = cells[4]
		id = fifthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let sixthItem = cells[5]
		id = sixthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
		
		let seventhItem = cells[6]
		id = seventhItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
		
		let eigthItem = cells[7]
		id = eigthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
		
		let ninthItem = cells[8]
		id = ninthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
	}
	
	func testDynamicTableViewModelForInvalidTestResult() {
		let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .invalid)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 4)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fourthItem = cells[3]
		id = fourthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
	}
	
	func testDynamicTableViewModelForPendingTestResult() {
		let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .pending)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 2)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 3)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let section2 = model.dynamicTableViewModel.section(1)
		let iconCell = section2.cells
		XCTAssertEqual(iconCell.count, 1)
		
		let iconCellFirstItem = iconCell[0]
		let iconId = iconCellFirstItem.cellReuseIdentifier
		XCTAssertEqual(iconId.rawValue, "iconCell")
	}
	
	func testDynamicTableViewModelForExpiredTestResult() {
		let coronaTestService = CoronaTestService(client: ClientMock(), store: MockTestStore())
		coronaTestService.pcrTest = PCRTest.mock(testResult: .expired)

		let model = ExposureSubmissionTestResultViewModel(
			coronaTestType: .pcr,
			coronaTestService: coronaTestService,
			onSubmissionConsentCellTap: { _ in },
			onContinueWithSymptomsFlowButtonTap: { },
			onContinueWarnOthersButtonTap: { _ in },
			onChangeToPositiveTestResult: { },
			onTestDeleted: { }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 4)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fourthItem = cells[3]
		id = fourthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
	}
	
}
