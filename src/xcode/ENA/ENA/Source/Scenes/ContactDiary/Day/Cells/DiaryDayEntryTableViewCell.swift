////
// 🦠 Corona-Warn-App
//

import UIKit

class DiaryDayEntryTableViewCell: UITableViewCell, UITextFieldDelegate {

	// MARK: - Overrides

	override func awakeFromNib() {
		super.awakeFromNib()

		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
		headerStackView.addGestureRecognizer(tapGestureRecognizer)
		headerStackView.isUserInteractionEnabled = true
	}

	// MARK: - Protocol UITextFieldDelegate

	func textFieldDidEndEditing(_ textField: UITextField) {
		switch cellModel.entryType {
		case .contactPerson:
			updateContactPersonEncounter()
		case .location:
			updateLocationVisit()
		}
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		endEditing(true)
	}
	
	func setEdit(to editing: Bool) {
		cellInEditMode = editing
		
		if editing {
			checkboxImageView.image = UIImage(named: "Icons_Grey_Entfernen")
		} else {
			checkboxImageView.image = cellModel.image
		}
	}	

	// MARK: - Internal

	func configure(
		cellModel: DiaryDayEntryCellModel,
		onInfoButtonTap: @escaping () -> Void,
		onEditEntry: @escaping (DiaryEntry) -> Void,
		onDeleteEntry: @escaping (DiaryEntry) -> Void
	) {
		self.cellModel = cellModel
		self.onInfoButtonTap = onInfoButtonTap
		self.onEditEntry = onEditEntry
		self.onDeleteEntry = onDeleteEntry

		checkboxImageView.image = cellModel.image
		label.text = cellModel.text
		label.font = cellModel.font

		setUpParameterViews()

		parametersContainerStackView.isHidden = cellModel.parametersHidden

		durationSegmentedControl.selectedSegmentIndex = cellModel.selectedDurationSegmentIndex
		maskSituationSegmentedControl.selectedSegmentIndex = cellModel.selectedMaskSituationSegmentIndex
		settingSegmentedControl.selectedSegmentIndex = cellModel.selectedSettingSegmentIndex
		visitDurationPicker.date = Date.dateWithMinutes(cellModel.locationVisitDuration) ?? Date()
		notesTextField.text = cellModel.circumstances

		accessibilityTraits = cellModel.accessibilityTraits
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(checkboxImageViewClicked))

		// add it to the image view;
		checkboxImageView.addGestureRecognizer(tapGesture)
		// make sure imageView can be interacted with by user
		checkboxImageView.isUserInteractionEnabled = true
	}

	// MARK: - Private

	private var cellModel: DiaryDayEntryCellModel!
	private var onInfoButtonTap: (() -> Void)!
	private var cellInEditMode: Bool = false
	private var onEditEntry: ((DiaryEntry) -> Void)?
	private var onDeleteEntry: ((DiaryEntry) -> Void)?

	@IBOutlet private weak var label: ENALabel!
	@IBOutlet private weak var checkboxImageView: UIImageView!
	@IBOutlet private weak var headerStackView: UIStackView!
	@IBOutlet private weak var parametersContainerStackView: UIStackView!
	@IBOutlet private weak var parametersStackView: UIStackView!

	private lazy var durationSegmentedControl: DiarySegmentedControl = {
		let segmentedControl = DiarySegmentedControl(items: cellModel.durationValues.map { $0.title })
		segmentedControl.addTarget(self, action: #selector(durationValueChanged(sender:)), for: .valueChanged)
		segmentedControl.accessibilityIdentifier = AccessibilityIdentifiers.ContactDiaryInformation.Day.durationSegmentedContol
		return segmentedControl
	}()

	private lazy var maskSituationSegmentedControl: DiarySegmentedControl = {
		let segmentedControl = DiarySegmentedControl(items: cellModel.maskSituationValues.map { $0.title })
		segmentedControl.addTarget(self, action: #selector(maskSituationValueChanged(sender:)), for: .valueChanged)
		segmentedControl.accessibilityIdentifier = AccessibilityIdentifiers.ContactDiaryInformation.Day.maskSituationSegmentedControl
		return segmentedControl
	}()

	private lazy var settingSegmentedControl: DiarySegmentedControl = {
		let segmentedControl = DiarySegmentedControl(items: cellModel.settingValues.map { $0.title })
		segmentedControl.addTarget(self, action: #selector(settingValueChanged(sender:)), for: .valueChanged)
		segmentedControl.accessibilityIdentifier = AccessibilityIdentifiers.ContactDiaryInformation.Day.settingSegmentedControl
		return segmentedControl
	}()

	private lazy var notesTextField: ENATextField = {
		let textField = ENATextField(frame: .zero)
		textField.accessibilityIdentifier = AccessibilityIdentifiers.ContactDiaryInformation.Day.notesTextField
		textField.backgroundColor = .enaColor(for: .darkBackground)
		textField.clearButtonMode = .whileEditing
		textField.textColor = .enaColor(for: .textPrimary1)
		textField.returnKeyType = .done
		textField.delegate = self
		textField.layer.borderWidth = 0

		textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40.0).isActive = true

		return textField
	}()

	private lazy var notesInfoButton: UIButton = {
		let button = UIButton(type: .infoLight)
		button.accessibilityIdentifier = AccessibilityIdentifiers.ContactDiaryInformation.Day.notesInfoButton
		button.tintColor = .enaColor(for: .tint)
		button.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
		button.setContentCompressionResistancePriority(.required, for: .horizontal)

		return button
	}()

	private lazy var notesStackView: UIStackView = {
		let stackView = UIStackView()
		stackView.axis = .horizontal
		stackView.spacing = 8

		stackView.addArrangedSubview(notesTextField)
		stackView.addArrangedSubview(notesInfoButton)

		return stackView
	}()

	private lazy var visitDurationPicker: UIDatePicker = {
		let durationPicker = UIDatePicker()
		if #available(iOS 14.0, *) {
			// UIDatePickers behave differently on iOS 14+. The .valueChanged event would be called too early and reload the cell before the animation is finished.
			// The .editingDidEnd event is triggered after the animation is finished.
			durationPicker.addTarget(self, action: #selector(updateLocationVisit), for: .editingDidEnd)
		} else {
			// Before iOS 14 .editingDidEnd was not called at all, therefore we use .valueChanged, which was called after the animation is finished.
			durationPicker.addTarget(self, action: #selector(updateLocationVisit), for: .valueChanged)
		}
		// German locale ensures 24h format.
		durationPicker.locale = Locale(identifier: "de_DE")
		durationPicker.datePickerMode = .time
		durationPicker.minuteInterval = 15
		durationPicker.tintColor = .enaColor(for: .tint)

		if #available(iOS 14.0, *) {
			durationPicker.preferredDatePickerStyle = .inline
		}

		durationPicker.widthAnchor.constraint(lessThanOrEqualToConstant: 100).isActive = true

		return durationPicker
	}()

	private lazy var visitDurationStackView: UIStackView = {
		let stackView = UIStackView()
		stackView.axis = .horizontal
		stackView.spacing = 8

		let label = ENALabel()
		label.style = .body
		label.text = AppStrings.ContactDiary.Day.Visit.duration

		stackView.addArrangedSubview(label)
		stackView.addArrangedSubview(visitDurationPicker)

		return stackView
	}()

	private func setUpParameterViews() {
		parametersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

		switch cellModel.entryType {
		case .contactPerson:
			parametersStackView.addArrangedSubview(durationSegmentedControl)
			parametersStackView.addArrangedSubview(maskSituationSegmentedControl)
			parametersStackView.addArrangedSubview(settingSegmentedControl)

			parametersStackView.setCustomSpacing(16, after: settingSegmentedControl)

			notesTextField.placeholder = AppStrings.ContactDiary.Day.Encounter.notesPlaceholder
		case .location:
			parametersStackView.addArrangedSubview(visitDurationStackView)

			notesTextField.placeholder = AppStrings.ContactDiary.Day.Visit.notesPlaceholder
		}

		parametersStackView.addArrangedSubview(notesStackView)
	}
	
	private func updateContactPersonEncounter() {
		let circumstances = notesTextField.text ?? ""
		guard cellModel.circumstances != circumstances else {
			// no need to trigger an update if nothing changed
			return
		}
		cellModel.updateContactPersonEncounter(circumstances: circumstances)
	}

	@objc
	private func updateLocationVisit() {
		let circumstances = notesTextField.text ?? ""
		let duration = visitDurationPicker.date.todaysMinutes
		guard duration != cellModel.locationVisitDuration || cellModel.circumstances != circumstances else {
			// no need to trigger an update if nothing changed
			return
		}
		cellModel.updateLocationVisit(durationInMinutes: visitDurationPicker.date.todaysMinutes, circumstances: notesTextField.text ?? "")
	}

	@objc
	private func headerTapped() {
		if cellInEditMode {
			self.onEditEntry?(cellModel.entry)
			return
		}
		cellModel.toggleSelection()
	}

	@objc
	private func durationValueChanged(sender: UISegmentedControl) {
		cellModel.selectDuration(at: sender.selectedSegmentIndex)
	}

	@objc
	private func maskSituationValueChanged(sender: UISegmentedControl) {
		cellModel.selectMaskSituation(at: sender.selectedSegmentIndex)
	}

	@objc
	private func settingValueChanged(sender: UISegmentedControl) {
		cellModel.selectSetting(at: sender.selectedSegmentIndex)
	}

	@objc
	private func infoButtonTapped() {
		onInfoButtonTap()
	}
    
	@objc
	func checkboxImageViewClicked(_ sender: Any) {
		if cellInEditMode {
			self.onDeleteEntry?(cellModel.entry)
		} else {
			cellModel.toggleSelection()
		}
	}

}
