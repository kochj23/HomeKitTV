//
//  WatchPhoneConnectivity.swift
//  HomeKitTV Watch App
//
//  Watch Connectivity handler for communication with iPhone/tvOS
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import WatchConnectivity
import SwiftUI

@MainActor
class WatchPhoneConnectivity: NSObject, ObservableObject {
    static let shared = WatchPhoneConnectivity()

    // MARK: - Published Properties

    @Published var isReachable: Bool = false
    @Published var isActivated: Bool = false
    @Published var pendingCommand: Bool = false

    // MARK: - Private Properties

    private var session: WCSession?
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Initialization

    override private init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    deinit {
        session?.delegate = nil
    }

    // MARK: - Commands

    /// Request full data sync from phone
    func requestSync() {
        let command = WatchCommandPayload(command: .refreshData)
        sendCommand(command)
    }

    /// Execute a scene
    func executeScene(id: String) {
        let command = WatchCommandPayload(command: .executeScene, targetId: id)
        sendCommand(command)

        // Haptic feedback
        WKInterfaceDevice.current().play(.click)
    }

    /// Toggle an accessory on/off
    func toggleAccessory(id: String) {
        let command = WatchCommandPayload(command: .toggleAccessory, targetId: id)
        sendCommand(command)

        WKInterfaceDevice.current().play(.click)
    }

    /// Set accessory brightness
    func setAccessoryBrightness(id: String, brightness: Int) {
        let command = WatchCommandPayload(command: .setAccessoryBrightness, targetId: id, value: Double(brightness))
        sendCommand(command)
    }

    /// Set thermostat temperature
    func setThermostatTemperature(id: String, temperature: Double) {
        let command = WatchCommandPayload(command: .setThermostatTemperature, targetId: id, value: temperature)
        sendCommand(command)
    }

    // MARK: - Private Methods

    private func sendCommand(_ command: WatchCommandPayload) {
        guard let session = session, session.isReachable else {
            WatchDataStore.shared.lastError = "Phone not reachable"
            WKInterfaceDevice.current().play(.failure)
            return
        }

        pendingCommand = true

        do {
            let data = try encoder.encode(command)
            let message: [String: Any] = [WatchMessageKeys.command: data]

            session.sendMessage(message, replyHandler: { [weak self] reply in
                Task { @MainActor in
                    self?.handleReply(reply)
                }
            }, errorHandler: { [weak self] error in
                Task { @MainActor in
                    self?.pendingCommand = false
                    WatchDataStore.shared.lastError = error.localizedDescription
                    WKInterfaceDevice.current().play(.failure)
                }
            })
        } catch {
            pendingCommand = false
            WatchDataStore.shared.lastError = "Failed to encode command"
        }
    }

    private func handleReply(_ reply: [String: Any]) {
        pendingCommand = false

        if let responseData = reply[WatchMessageKeys.response] as? Data,
           let response = try? decoder.decode(WatchCommandResponse.self, from: responseData) {

            if response.success {
                WKInterfaceDevice.current().play(.success)

                // Update accessory state if provided
                if let updatedAccessory = response.updatedAccessory {
                    WatchDataStore.shared.updateAccessoryState(updatedAccessory)
                }
            } else {
                WKInterfaceDevice.current().play(.failure)
                WatchDataStore.shared.lastError = response.message ?? "Command failed"
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchPhoneConnectivity: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isActivated = activationState == .activated
            self.isReachable = session.isReachable

            if activationState == .activated {
                // Request initial sync
                self.requestSync()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable

            if session.isReachable && WatchDataStore.shared.isDataStale {
                self.requestSync()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleIncomingMessage(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            handleIncomingMessage(applicationContext)
        }
    }

    @MainActor
    private func handleIncomingMessage(_ message: [String: Any]) {
        // Handle home data update
        if let homeDataBytes = message[WatchMessageKeys.homeData] as? Data,
           let homeData = try? decoder.decode(WatchHomeData.self, from: homeDataBytes) {
            WatchDataStore.shared.updateWithHomeData(homeData)
        }

        // Handle single accessory update
        if let accessoryData = message[WatchMessageKeys.accessoryUpdate] as? Data,
           let accessory = try? decoder.decode(WatchAccessory.self, from: accessoryData) {
            WatchDataStore.shared.updateAccessoryState(accessory)
        }

        // Handle scene execution notification
        if let sceneId = message[WatchMessageKeys.sceneExecuted] as? String {
            // Show notification that scene was executed
            WKInterfaceDevice.current().play(.notification)
        }
    }
}
