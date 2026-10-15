import UIKit
import Combine
import AVFoundation

// MARK: - VideoPlayerViewController
// Implements the Video Player screen with custom controls:
// - AVPlayerLayer video presentation
// - Play / Pause, Rewind 10s, Forward 10s
// - Interactive Scrubber (UISlider) with live time updates
// - Buffering indicators & Error handling
// - Lifecycle management (app backgrounding, deinit observer cleanup)
// - Orientation support: Portrait & Landscape auto-rotation
// - IBOutlets wired directly from Player.storyboard

final class VideoPlayerViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet private weak var videoContainerView: UIView!
    @IBOutlet private weak var overlayView: UIView!
    @IBOutlet private weak var dismissButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var rewindButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var forwardButton: UIButton!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var currentTimeLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var progressSlider: UISlider!

    // MARK: - Dependencies & State
    private var viewModel: (any VideoPlayerViewModelProtocol)!
    private var cancellables = Set<AnyCancellable>()
    private var playerLayer: AVPlayerLayer?
    private var isScrubbing = false
    private var autoHideControlsTimer: Timer?

    // MARK: - Init
    init(viewModel: any VideoPlayerViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Injects ViewModel when instantiated from Player.storyboard
    func configure(viewModel: any VideoPlayerViewModelProtocol) {
        self.viewModel = viewModel
        if isViewLoaded {
            setupPlayerLayer()
            bindViewModel()
        }
    }

    // MARK: - Orientation Support
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        forceLandscapeOrientation()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        forceLandscapeOrientation()
    }

    private func forceLandscapeOrientation() {
        if #available(iOS 16.0, *) {
            guard let windowScene = view.window?.windowScene else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.playerLayer?.frame = CGRect(origin: .zero, size: size)
        })
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTapGesture()
        setupLifecycleObservers()

        if viewModel != nil {
            setupPlayerLayer()
            bindViewModel()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            forcePortraitOrientation()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            cleanupPlayer()
        }
    }

    private func forcePortraitOrientation() {
        if #available(iOS 16.0, *) {
            guard let windowScene = view.window?.windowScene else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }

    deinit {
        cleanupPlayer()
    }

    // MARK: - UI & Gesture Setup
    private func setupUI() {
        view.backgroundColor = .black
        titleLabel.text = viewModel?.title
        updatePlayPauseButton(isPlaying: viewModel?.isPlaying ?? true)

        // Style the scrubber slider
        let sliderThumb = UIImage(systemName: "circle.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        progressSlider.setThumbImage(sliderThumb, for: .normal)
        progressSlider.setThumbImage(sliderThumb, for: .highlighted)
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    private func setupPlayerLayer() {
        guard let vm = viewModel else { return }
        let layer = AVPlayerLayer(player: vm.player)
        layer.videoGravity = .resizeAspect
        layer.frame = videoContainerView.bounds
        videoContainerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        videoContainerView.layer.addSublayer(layer)
        self.playerLayer = layer
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        guard let vm = viewModel else { return }

        titleLabel.text = vm.title

        // 1. Play / Pause state
        vm.isPlayingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.updatePlayPauseButton(isPlaying: isPlaying)
                if isPlaying {
                    self?.scheduleAutoHideControls()
                } else {
                    self?.showControls()
                }
            }
            .store(in: &cancellables)

        // 2. Buffering state (show/hide spinner without hiding the play/pause button)
        vm.isBufferingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBuffering in
                if isBuffering {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        // 3. Playback progress (currentTime, duration, slider)
        vm.currentTimeFormattedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] formattedTime in
                guard let self = self, !self.isScrubbing else { return }
                self.currentTimeLabel.text = formattedTime
            }
            .store(in: &cancellables)

        vm.durationFormattedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] formattedDuration in
                self?.durationLabel.text = formattedDuration
            }
            .store(in: &cancellables)

        vm.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self, !self.isScrubbing else { return }
                self.progressSlider.value = progress
            }
            .store(in: &cancellables)

        // 4. Playback Completed
        vm.isCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCompleted in
                if isCompleted {
                    self?.showControls()
                }
            }
            .store(in: &cancellables)

        // 5. Error handling
        vm.errorMessagePublisher
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMsg in
                self?.showErrorAlert(message: errorMsg)
            }
            .store(in: &cancellables)
    }

    private func updatePlayPauseButton(isPlaying: Bool) {
        let iconName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 56)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        playPauseButton.setImage(image, for: .normal)
        playPauseButton.setImage(image, for: .highlighted)
        playPauseButton.setImage(image, for: .selected)
        if var btnConfig = playPauseButton.configuration {
            btnConfig.image = image
            playPauseButton.configuration = btnConfig
        }
    }

    // MARK: - Lifecycle Management (Requirement #4)
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        viewModel?.handleAppDidEnterBackground()
    }

    private func cleanupPlayer() {
        autoHideControlsTimer?.invalidate()
        autoHideControlsTimer = nil
        viewModel?.teardown()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Controls Visibility (Auto-Hide)
    @objc private func didTapView() {
        if overlayView.alpha > 0 {
            hideControls()
        } else {
            showControls()
            if viewModel?.isPlaying == true {
                scheduleAutoHideControls()
            }
        }
    }

    private func showControls() {
        autoHideControlsTimer?.invalidate()
        UIView.animate(withDuration: 0.25) {
            self.overlayView.alpha = 1.0
        }
    }

    private func hideControls() {
        autoHideControlsTimer?.invalidate()
        UIView.animate(withDuration: 0.25) {
            self.overlayView.alpha = 0.0
        }
    }

    private func scheduleAutoHideControls() {
        autoHideControlsTimer?.invalidate()
        autoHideControlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }

    // MARK: - IBActions
    @IBAction private func didTapDismiss(_ sender: UIButton) {
        forcePortraitOrientation()
        cleanupPlayer()
        dismiss(animated: true)
    }

    @IBAction private func didTapPlayPause(_ sender: UIButton) {
        viewModel?.togglePlayPause()
    }

    @IBAction private func didTapRewind(_ sender: UIButton) {
        viewModel?.seekBy(seconds: -10)
    }

    @IBAction private func didTapForward(_ sender: UIButton) {
        viewModel?.seekBy(seconds: 10)
    }

    @IBAction private func progressSliderTouchDown(_ sender: UISlider) {
        isScrubbing = true
        autoHideControlsTimer?.invalidate()
    }

    @IBAction private func progressSliderValueChanged(_ sender: UISlider) {
        let progressVal = sender.value
        currentTimeLabel.text = String(format: "%.0f%%", progressVal * 100)
    }

    @IBAction private func progressSliderTouchUp(_ sender: UISlider) {
        viewModel?.seek(toProgress: sender.value)
        isScrubbing = false
        if viewModel?.isPlaying == true {
            scheduleAutoHideControls()
        }
    }

    // MARK: - Error Presentation
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Playback Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
            self?.didTapDismiss(UIButton())
        })
        present(alert, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension VideoPlayerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Prevent background tap gesture from intercepting touches on buttons or sliders
        if touch.view is UIControl || touch.view?.superview is UIControl {
            return false
        }
        return true
    }
}
